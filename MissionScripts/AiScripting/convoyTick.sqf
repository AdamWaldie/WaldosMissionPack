/*
 * Author: WaldoTheWarfighter
 * Maintains bounded lead breadcrumbs, damped spacing speed and corner slowdown. No FSMs, path broadcasts or teleports.
 * Locality/authority: server owns registration; driving commands execute only on current owners.
 * Repeat/JIP: ordered registry snapshots replace old settings; owner-local paths rebuild on migration.
 * Arguments: 0: group <GROUP>; 1: configuration <ARRAY> [revision, km/h, metres, pushThrough, vehicles].
 * Return Value: Nothing.
 * Current callers: single round-robin ConvoySync worker.
 * Example: [_group, _configuration] call Waldo_fnc_ConvoyTick;
 */
params ["_group", "_configuration"];
if (isNull _group || {!local _group}) exitWith {};
_configuration params ["_revision", "_speed", "_separation", "_pushThrough", "_registered"];
private _state = _group getVariable ["Waldo_Convoy_LocalState", createHashMap];
if (time < (_state getOrDefault ["due", -1])) exitWith {};
private _paused = [] call Waldo_fnc_AIPassIsPaused;
private _playerCrew = _registered findIf {(crew _x) findIf {isPlayer _x} >= 0} >= 0;
private _zeus = [_group] call Waldo_fnc_AIPassZeusHeld;
if (_paused || {_playerCrew} || {_zeus} || {!_pushThrough && {behaviour leader _group == "COMBAT"}}) exitWith {
    if (count _state > 0) then {[_group, false] call Waldo_fnc_ConvoyReleaseLocal};
};
private _vehicles = _registered select {alive _x && {canMove _x} && {local _x} && {alive driver _x} && {local driver _x}
    && {group driver _x == _group} && {!((driver _x) getVariable ["ACE_isUnconscious", false])} && {lifeState driver _x != "INCAPACITATED"}};
// Group and vehicle locality can settle on different frames; do not stop a healthy convoy mid-transfer.
if (count _vehicles < 2 && {count (_registered select {alive _x && {canMove _x} && {alive driver _x}}) >= 2}) exitWith {};
if (count _vehicles < 2) exitWith {
    [_group] call Waldo_fnc_ConvoyReleaseLocal;
    [_group, 0] remoteExecCall ["Waldo_fnc_SimpleAiConvoy", 2];
};
if (isNil {_group getVariable "Waldo_Convoy_Restore"}) then {
    _group setVariable ["Waldo_Convoy_Restore", [formation _group, attackEnabled _group,
        _registered apply {[_x, getForcedSpeed _x, getUnloadInCombat _x]}], true];
};
private _lead = _vehicles select 0;
if (!(vehicle leader _group in _vehicles)) then {_group selectLeader driver _lead};
if ((_state getOrDefault ["revision", -1]) != _revision || {(_state getOrDefault ["lead", objNull]) != _lead}) then {
    [_group, false] call Waldo_fnc_ConvoyReleaseLocal;
    _state = createHashMapFromArray [["revision", _revision], ["lead", _lead], ["trail", [getPosATL _lead]], ["trailBase", 0], ["heading", getDir _lead], ["followers", createHashMap]];
    _group setVariable ["Waldo_Convoy_LocalState", _state];
    _group setFormation "COLUMN";
    if (_pushThrough) then {_group enableAttack false; {_x setUnloadInCombat [false, false]} forEach _vehicles};
};
_state set ["due", time + 1];
private _trail = _state get "trail";
if ((_trail select (count _trail - 1)) distance2D _lead >= 5) then {_trail pushBack getPosATL _lead};
if (count _trail > 128) then {
    private _remove = count _trail - 128;
    _trail deleteRange [0, _remove];
    _state set ["trailBase", (_state get "trailBase") + _remove];
};
private _trailBase = _state get "trailBase";
private _turn = abs (((getDir _lead - (_state get "heading") + 540) mod 360) - 180);
_state set ["heading", getDir _lead];
private _largestGap = 0;
for "_i" from 1 to (count _vehicles - 1) do {_largestGap = _largestGap max ((_vehicles select _i) distance2D (_vehicles select (_i - 1)))};
private _leadLimit = (_speed - ((_largestGap - _separation * 2) max 0) * 0.12 - (_turn min 60) * 0.4) max 5;
_lead forceSpeed (_leadLimit / 3.6);
private _followers = _state get "followers";
for "_i" from 1 to (count _vehicles - 1) do {
    private _vehicle = _vehicles select _i;
    private _front = _vehicles select (_i - 1);
    private _gap = _vehicle distance2D _front;
    private _limit = ((abs speed _front) + (_gap - _separation) * 0.65 - ((abs speed _vehicle) - (abs speed _front)) * 0.25) max 0;
    _vehicle forceSpeed ((_limit min (_speed * 1.15)) / 3.6);
    private _key = netId _vehicle;
    private _progress = _followers getOrDefault [_key, [getPosATL _vehicle, time, -1, _trailBase]];
    if (_vehicle distance2D (_progress select 0) > 3) then {_progress = [getPosATL _vehicle, time, _progress select 2, _progress select 3]};
    // Let the normal engine route around an obstruction after a bounded timeout. Never teleport.
    if (time - (_progress select 1) > 20 && {_gap > _separation * 2}) then {
        driver _vehicle doFollow leader _group;
        _progress = [getPosATL _vehicle, time, time + 10, _progress select 3];
    };
    if (time >= (_progress select 2) && {count _trail >= 3} && {_gap > _separation * 0.8}) then {
        private _nearest = -1;
        private _distance = 18;
        private _frontIndex = if (_i == 1) then {count _trail - 1} else {((_followers get (netId _front)) select 3) - _trailBase};
        private _start = ((_progress select 3) - _trailBase) max 0;
        for "_j" from _start to (_frontIndex min (count _trail - 1)) do {
            private _d = _vehicle distance2D (_trail select _j);
            if (_d < _distance) then {_distance = _d; _nearest = _j};
        };
        if (_nearest >= 0) then {
            private _path = [];
            _progress set [3, _nearest + _trailBase];
            private _end = (_nearest + 10) min _frontIndex min (count _trail - 1);
            for "_j" from (_nearest + 1) to _end do {
                private _point = _trail select _j;
                if (_point distance2D _front > _separation * 0.7 && {(_front distance2D _point) < _gap}) then {_path pushBack _point};
            };
            if (count _path >= 2) then {doStop driver _vehicle; _vehicle setDriveOnPath _path; _progress set [2, time + 3]};
        } else {
            // After migration the previous owner's trail is intentionally not broadcast. Rejoin
            // through normal pathfinding until the follower reaches the new sampled trail.
            driver _vehicle doFollow leader _group;
            _progress set [2, time + 5];
        };
    };
    _followers set [_key, _progress];
};

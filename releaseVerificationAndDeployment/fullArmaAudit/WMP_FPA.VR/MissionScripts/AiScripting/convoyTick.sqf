/*
 * Author: WaldoTheWarfighter
 * Drives mixed convoys, detects finite-route arrival and requests a persistent halt after pinned contact.
 * Locality/authority: server owns phase; group owner drives and reports, each cargo/turret owner applies crew work.
 * Repeat/JIP: ordered snapshots carry phase/cargo/baselines; a five-second contact checkpoint survives HC migration.
 * Arguments: 0: group <GROUP>; 1: configuration <ARRAY> [revision, km/h, gap, pushThrough, vehicles, phase, cargo, restore].
 * Return Value: Nothing.
 * Current callers: single round-robin ConvoySync worker on server/headless clients.
 * Example: [_group, _configuration] call Waldo_fnc_ConvoyTick;
 */
params ["_group", "_configuration"];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {};
if (isNull _group) exitWith {};
_configuration params ["_revision", "_speed", "_separation", "_pushThrough", "_registered", "_phase", "_cargo", "_restore"];
if (time < (_group getVariable ["Waldo_Convoy_NextTick", -1])) exitWith {};
_group setVariable ["Waldo_Convoy_NextTick", time + 1];
private _state = _group getVariable ["Waldo_Convoy_LocalState", createHashMap];
private _paused = [] call Waldo_fnc_AIPassIsPaused;
private _playerCrew = _registered findIf {(crew _x) findIf {isPlayer _x || {!isNull (_x getVariable ["bis_fnc_moduleRemoteControl_owner", objNull])}} >= 0} >= 0;
private _zeus = [_group] call Waldo_fnc_AIPassZeusHeld;
if (_paused || {_playerCrew} || {_zeus}) exitWith {
    if (!(_group getVariable ["Waldo_Convoy_Suspended", false])) then {
        [_group, false, _restore] call Waldo_fnc_ConvoyReleaseLocal;
        _group setVariable ["Waldo_Convoy_Suspended", true];
        if (local _group) then {_group setVariable ["Waldo_Convoy_ContactProgress", nil, true]};
    };
};
_group setVariable ["Waldo_Convoy_Suspended", false];
[_group, _configuration] call Waldo_fnc_ConvoyCrewLocal;
if (_phase == "HALT" || {!local _group}) exitWith {};
private _vehicles = _registered select {alive _x && {canMove _x} && {local _x} && {alive driver _x} && {local driver _x}
    && {group driver _x == _group} && {!((driver _x) getVariable ["ACE_isUnconscious", false])} && {lifeState driver _x != "INCAPACITATED"}};
// Do not treat temporary split locality as damage or arrival.
if (count _vehicles < count (_registered select {alive _x && {canMove _x} && {alive driver _x} && {group driver _x == _group}})) exitWith {};
if (_vehicles isEqualTo []) exitWith {
    if (time >= (_state getOrDefault ["haltRequest", -1])) then {
        [_group, _revision, "IMMOBILE"] remoteExecCall ["Waldo_fnc_ConvoyHaltServer", 2];
        _state set ["haltRequest", time + 5];
        _group setVariable ["Waldo_Convoy_LocalState", _state];
    };
};
private _lead = _vehicles select 0;
if (!(vehicle leader _group in _vehicles)) then {_group selectLeader driver _lead};
if ((_state getOrDefault ["revision", -1]) != _revision || {(_state getOrDefault ["lead", objNull]) != _lead} || {_vehicles isNotEqualTo (_state getOrDefault ["vehicles", []])}) then {
    [_group, false, _restore, _registered] call Waldo_fnc_ConvoyReleaseLocal;
    private _savedProgress = _group getVariable ["Waldo_Convoy_ContactProgress", []];
    private _progress = if (_savedProgress isNotEqualTo [] && {(_savedProgress select 0) == _revision}) then {+(_savedProgress select 1)} else {[]};
    _state = createHashMapFromArray [["revision", _revision], ["lead", _lead], ["trail", [getPosATL _lead]], ["trailBase", 0],
        ["heading", getDir _lead], ["vehicles", +_vehicles], ["followers", createHashMap], ["contactProgress", _progress]];
    _group setVariable ["Waldo_Convoy_LocalState", _state];
    private _specs = createHashMap;
    {
        private _bounds = boundingBoxReal _x;
        _specs set [netId _x, [getNumber (configOf _x >> "maxSpeed"), abs (((_bounds select 1) select 1) - ((_bounds select 0) select 1))]];
    } forEach _vehicles;
    _state set ["specs", _specs];
    _group setFormation "COLUMN";
    // Vehicle movement remains a convoy task. Mounted gunners can fire without breaking formation.
    _group enableAttack false;
    // Clear a previous HALT doStop on the lead driver without deleting or replacing route waypoints.
    if (currentWaypoint _group < count waypoints _group) then {
        driver _lead doMove (waypointPosition [_group, currentWaypoint _group]);
    };
    {_x setUnloadInCombat [false, false]} forEach _vehicles;
};
// Query existing group knowledge at most every five seconds; never reveal hidden attackers.
if (time >= (_state getOrDefault ["contactDue", -1])) then {
    private _observer = leader _group;
    private _enemy = _observer findNearestEnemy _observer;
    private _knowledge = _observer targetKnowledge _enemy;
    private _contact = !isNull _enemy && {alive _enemy} && {_observer knowsAbout _enemy >= 1.5}
        && {_observer distance2D (_observer getHideFrom _enemy) <= 800}
        && {time - ((_knowledge select 2) max (_knowledge select 3)) <= 30};
    _contact = _contact || {(units _group) findIf {alive _x && {getSuppression _x > 0.2}} >= 0};
    _state set ["contact", _contact];
    _state set ["contactDue", time + 5];
};
private _contact = _state getOrDefault ["contact", false];
private _pinned = false;
private _contactProgress = _state getOrDefault ["contactProgress", []];
if (_contact) then {
    {
        private _vehicle = _x;
        if (alive _vehicle) then {
            private _index = _contactProgress findIf {(_x select 0) == _vehicle};
            if (_index < 0) then {_contactProgress pushBack [_vehicle, getPosATL _vehicle, serverTime]; _index = count _contactProgress - 1};
            private _entry = _contactProgress select _index;
            if (_vehicle distance2D (_entry select 1) >= 3) then {_entry = [_vehicle, getPosATL _vehicle, serverTime]; _contactProgress set [_index, _entry]};
            if (serverTime - (_entry select 2) >= 15 && {abs speed _vehicle < 3}) then {_pinned = true};
        };
    } forEach _registered;
} else {_contactProgress = []};
_state set ["contactProgress", _contactProgress];
if (time >= (_state getOrDefault ["checkpointDue", -1])) then {
    private _checkpoint = [_revision, _contactProgress apply {+_x}];
    if (_checkpoint isNotEqualTo (_group getVariable ["Waldo_Convoy_ContactProgress", []])) then {_group setVariable ["Waldo_Convoy_ContactProgress", _checkpoint, true]};
    _state set ["checkpointDue", time + 5];
};
if (_contact && {!_pushThrough || {_pinned}}) exitWith {
    if (time >= (_state getOrDefault ["haltRequest", -1])) then {
        [_group, _revision, "AMBUSH"] remoteExecCall ["Waldo_fnc_ConvoyHaltServer", 2];
        _state set ["haltRequest", time + 5];
    };
};
// Size-aware gaps prevent a long IFV and a truck from being treated like two short cars.
private _gaps = [0];
private _maximum = _speed;
private _specs = _state get "specs";
for "_i" from 0 to (count _vehicles - 1) do {
    private _vehicle = _vehicles select _i;
    private _topSpeed = (_specs get (netId _vehicle)) select 0;
    if (_topSpeed > 0) then {_maximum = _maximum min (_topSpeed * 0.8)};
    if (_i > 0) then {
        private _front = _vehicles select (_i - 1);
        private _lengths = ((_specs get (netId _vehicle)) select 1) + ((_specs get (netId _front)) select 1);
        _gaps pushBack (_separation max (_lengths * 0.5 + 5));
    };
};
private _lastWaypoint = [_group, (count waypoints _group) - 1];
private _routeDone = count waypoints _group > 1 && {currentWaypoint _group >= count waypoints _group}
    && {_lead distance2D waypointPosition _lastWaypoint <= (waypointCompletionRadius _lastWaypoint max 20)};
private _settled = _routeDone && {_vehicles findIf {abs speed _x >= 1} < 0};
for "_i" from 1 to (count _vehicles - 1) do {
    if ((_vehicles select _i) distance2D (_vehicles select (_i - 1)) > (_gaps select _i) * 1.5) then {_settled = false};
};
if (!_settled) then {_state set ["arrivalAt", time + 5]};
if (_settled && {time >= (_state getOrDefault ["arrivalAt", time + 5])}) exitWith {
    if (time >= (_state getOrDefault ["haltRequest", -1])) then {
        [_group, _revision, "ARRIVED"] remoteExecCall ["Waldo_fnc_ConvoyHaltServer", 2];
        _state set ["haltRequest", time + 5];
    };
};
if (isNil {_state get "arrivalAt"}) then {_state set ["arrivalAt", time + 5]};
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
private _stretch = 0;
for "_i" from 1 to (count _vehicles - 1) do {
    _stretch = _stretch max (((_vehicles select _i) distance2D (_vehicles select (_i - 1))) / (_gaps select _i));
};
// During contact, keep the front moving instead of waiting inside the ambush for a disabled rear vehicle.
private _leadLimit = (_maximum - ((_stretch - 1) max 0) * 5 - (_turn min 60) * 0.4) max 5;
if (!_contact && {_stretch > 3}) then {_leadLimit = 0};
if (_routeDone) then {_leadLimit = 0};
_lead forceSpeed (_leadLimit / 3.6);
private _followers = _state get "followers";
for "_i" from 1 to (count _vehicles - 1) do {
    private _vehicle = _vehicles select _i;
    private _front = _vehicles select (_i - 1);
    private _gap = _vehicle distance2D _front;
    private _desiredGap = _gaps select _i;
    private _native = _vehicle isKindOf "Tank" || {!isAISteeringComponentEnabled _vehicle};
    private _limit = ((abs speed _front) + (_gap - _desiredGap) * 0.65 - ((abs speed _vehicle) - (abs speed _front)) * 0.25) max 0;
    _vehicle forceSpeed ((_limit min _maximum) / 3.6);
    private _key = netId _vehicle;
    private _progress = _followers getOrDefault [_key, [getPosATL _vehicle, time, -1, _trailBase]];
    if (_vehicle distance2D (_progress select 0) > 3) then {_progress = [getPosATL _vehicle, time, _progress select 2, _progress select 3]};
    // Let the normal engine route around an obstruction after a bounded timeout. Never teleport.
    if (time - (_progress select 1) > 20 && {_gap > _desiredGap * 2}) then {
        driver _vehicle doFollow leader _group;
        _progress = [getPosATL _vehicle, time, time + 10, _progress select 3];
    };
    if (time >= (_progress select 2) && {count _trail >= 3} && {_gap > _desiredGap * 0.8}) then {
        private _nearest = -1;
        private _distance = 18;
        private _frontIndex = count _trail - 1;
        if (_i > 1) then {
            private _frontDistance = 1e9;
            {private _d = _front distance2D _x; if (_d < _frontDistance) then {_frontDistance = _d; _frontIndex = _forEachIndex}} forEach _trail;
        };
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
                if (_point distance2D _front > _desiredGap * 0.7 && {(_front distance2D _point) < _gap}) then {_path pushBack _point};
            };
            if (_native && {_path isNotEqualTo []}) then {
                // Tank/unsupported steering uses a native pathfinding destination, not the wheeled path command.
                driver _vehicle doMove (_path select (count _path - 1));
                _progress set [2, time + 5];
            } else {
                if (count _path >= 2) then {doStop driver _vehicle; _vehicle setDriveOnPath _path; _progress set [2, time + 3]};
            };
        } else {
            // After migration the previous owner's trail is intentionally not broadcast. Rejoin
            // through normal pathfinding until the follower reaches the new sampled trail.
            driver _vehicle doFollow leader _group;
            _progress set [2, time + 5];
        };
    };
    _followers set [_key, _progress];
};

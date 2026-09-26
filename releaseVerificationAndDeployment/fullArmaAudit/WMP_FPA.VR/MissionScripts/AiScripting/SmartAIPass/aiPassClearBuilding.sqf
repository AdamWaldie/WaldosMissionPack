/*
 * Author: WaldoTheWarfighter
 * Orders an AI group to clear a building room by room.
 *
 * The leader holds at the entrance side while the rest clear, each taking the
 * nearest position not yet cleared or reserved by someone else. A soldier clears a position by
 * reaching it (within 1.5 m) or after 25 s; the order ends when every position is cleared or after
 * 240 s, and the squad rejoins formation. The group is set to COMBAT for the clear, and its previous
 * behaviour is restored afterwards. While clearing, the squad does not flank, retreat or search, and
 * is not sent to reinforce others.
 * With LAMBS Waypoints loaded and Waldo_AIPass_LambsMode "SPLIT", the order is handed to
 * lambs_wp_fnc_taskCQB instead (disable with the "useLambs" option). The WMP clear needs the Smart AI
 * Pass running (Waldo_AIPass_Enable); the LAMBS hand-over does not.
 * Locality and authority: call where the group is local, or on the server, which forwards to the
 * owner. Non-server, non-owner copies do nothing.
 *
 * Review contract: Local job generations prevent replaced jobs from issuing orders. Eligibility is checked before dispatch and on each step. Public cleared-room indices, deadline and original behaviour survive handover; local movement assignments are rebuilt.
 *
 * Arguments:
 * 0: group <GROUP or OBJECT> - the group, or a unit in it
 * 1: target <OBJECT or ARRAY> - the building, or a position (the nearest building is used)
 * 2: options <HASHMAP> (optional) - useLambs (default true), radius for LAMBS (default 50)
 *
 * Return Value:
 * Boolean - true when the order was applied or forwarded
 *
 * Example:
 * [group this, nearestBuilding this] call Waldo_fnc_AIPassClearBuilding;
 * Result: the squad works through every room of the building.
 *
 * Current callers: mission scripts and the AI Orders ZEN module.
 */

params [["_group", grpNull, [grpNull, objNull]], ["_target", objNull, [objNull, []]], ["_options", createHashMap, [createHashMap]]];
if (_group isEqualType objNull) then {_group = group _group};
if (isNull _group) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!local _group) exitWith {
    if (isServer) then {[_group, _target, _options] remoteExecCall ["Waldo_fnc_AIPassClearBuilding", groupOwner _group]; true} else {false};
};
if !([_group] call Waldo_fnc_AIPassIsEligible) exitWith {false};
private _building = if (_target isEqualType objNull) then {_target} else {nearestBuilding _target};
if (isNull _building) exitWith {if (_options getOrDefault ["resume", false]) then {[_group] call Waldo_fnc_AIPassClearRelease}; false};
if ((_options getOrDefault ["useLambs", true]) && {isClass (configFile >> "CfgPatches" >> "lambs_wp")}
    && {toUpperANSI (missionNamespace getVariable ["Waldo_AIPass_LambsMode", "SPLIT"]) == "SPLIT"}) exitWith {
    [_group] call Waldo_fnc_AIPassClearRelease;
    [_group, getPosATL _building, _options getOrDefault ["radius", 50]] spawn lambs_wp_fnc_taskCQB;
    diag_log format ["[WMP AI PASS] %1 clear building handed to LAMBS (%2)", _group, typeOf _building];
    true
};
if !(missionNamespace getVariable ["Waldo_AIPass_Active", false]) exitWith {
    diag_log format ["[WMP AI PASS] %1 clear building refused: the Smart AI Pass is not running on this machine.", _group];
    false
};
private _positions = _building buildingPos -1;
if (_positions isEqualTo []) exitWith {false};
private _leader = leader _group;
private _team = (units _group) select {alive _x && {local _x} && {vehicle _x == _x} && {_x != _leader}};
if (_team isEqualTo []) exitWith {false};
if ((_group getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo []) then {[_group] call Waldo_fnc_AIPassGarrisonRelease};
if ((_group getVariable ["Waldo_AIPass_Defend", []]) isNotEqualTo []) then {[_group] call Waldo_fnc_AIPassDefendRelease};
private _previous = _group getVariable ["Waldo_AIPass_ClearOrder", []];
private _resume = _options getOrDefault ["resume", false] && {_previous isNotEqualTo []} && {(_previous select 0) == _building};
private _baseBehaviour = if (_previous isEqualTo []) then {behaviour _leader} else {_previous select 3};
private _cleared = if (_resume) then {+(_previous select 1)} else {[]};
private _deadline = if (_resume) then {_previous select 2} else {serverTime + 240};
if (serverTime >= _deadline) exitWith {[_group] call Waldo_fnc_AIPassClearRelease; false};
_group setVariable ["Waldo_AIPass_ClearOrder", [_building, _cleared, _deadline, _baseBehaviour], true];
_group setVariable ["Waldo_AIPass_ClearApplied", true];
private _generation = (_group getVariable ["Waldo_AIPass_ClearGeneration", 0]) + 1;
_group setVariable ["Waldo_AIPass_ClearGeneration", _generation];
_group setVariable ["Waldo_AIPass_ClearBuilding", true, true];
_group setBehaviour "COMBAT";
[{
    params ["_job"];
    private _group = _job get "group";
    if (isNull _group || {!local _group}) exitWith {-1};
    if ((_group getVariable ["Waldo_AIPass_ClearGeneration", -1]) != (_job get "generation")) exitWith {-1};
    private _finish = {
        if (!isNull _group) then {
            private _leader = leader _group;
            {if (alive _x && {local _x}) then {_x doFollow _leader}} forEach (_job get "team");
            if (behaviour _leader == "COMBAT") then {_group setBehaviour (_job get "baseBehaviour")};
            _group setVariable ["Waldo_AIPass_ClearBuilding", nil, true];
            _group setVariable ["Waldo_AIPass_ClearOrder", nil, true];
            _group setVariable ["Waldo_AIPass_ClearApplied", nil];
        };
        diag_log format ["[WMP AI PASS] %1 clear building finished (%2 of %3 positions)", _group, count (_job get "cleared"), count (_job get "positions")];
        -1
    };
    if (isNull _group || {!local _group} || {!(_group getVariable ["Waldo_AIPass_ClearBuilding", false])}
        || {!alive (_job get "building")} || {!(missionNamespace getVariable ["Waldo_AIPass_Active", false])}
        || {!([_group] call Waldo_fnc_AIPassIsEligible)}) exitWith {call _finish};
    private _positions = _job get "positions";
    private _cleared = _job get "cleared";
    // One entry per team member, in team order: [] or [positionIndex, assignedAt].
    private _assigned = _job get "assigned";
    private _now = time;
    private _before = count _cleared;
    {
        private _unit = _x;
        private _member = _forEachIndex;
        if (alive _unit && {local _unit}) then {
            private _current = _assigned select _member;
            if (_current isNotEqualTo []) then {
                _current params ["_index", "_since"];
                // Building positions are AGL; compare in ASL so upper floors and slopes measure true.
                if (((getPosASL _unit) vectorDistance (AGLToASL (_positions select _index))) <= 1.5 || {_now - _since > 25}) then {
                    _cleared pushBackUnique _index;
                    _assigned set [_member, []];
                    _current = [];
                };
            };
            if (_current isEqualTo []) then {
                private _taken = (_assigned select {_x isNotEqualTo []}) apply {_x select 0};
                private _best = -1;
                private _bestDistance = 1e6;
                {
                    if !(_forEachIndex in _cleared || {_forEachIndex in _taken}) then {
                        private _distance = (getPosASL _unit) vectorDistance (AGLToASL _x);
                        if (_distance < _bestDistance) then {_best = _forEachIndex; _bestDistance = _distance};
                    };
                } forEach _positions;
                if (_best >= 0) then {
                    _unit doMove (_positions select _best);
                    _assigned set [_member, [_best, _now]];
                };
            };
        };
    } forEach (_job get "team");
    if (count _cleared != _before) then {
        _group setVariable ["Waldo_AIPass_ClearOrder", [_job get "building", +_cleared, _job get "deadline", _job get "baseBehaviour"], true];
    };
    if (count _cleared >= count _positions || {serverTime > (_job get "deadline")} || {(_job get "team") findIf {alive _x} < 0}) exitWith {call _finish};
    1.5
}, createHashMapFromArray [
    ["group", _group], ["team", _team], ["positions", _positions], ["cleared", _cleared], ["building", _building], ["assigned", _team apply {[]}],
    ["deadline", _deadline], ["baseBehaviour", _baseBehaviour], ["generation", _generation]
], 0] call Waldo_fnc_AIPassQueueJob;
diag_log format ["[WMP AI PASS] %1 clearing %2 (%3 positions, %4 soldiers)", _group, typeOf _building, count _positions, count _team];
true

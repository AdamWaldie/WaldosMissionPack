/*
 * Author: WaldoTheWarfighter
 * Orders an AI group to clear a building room by room.
 *
 * Teams of one or two use every available soldier. Larger teams leave the leader outside
 * the traversal team, each remaining soldier taking the
 * nearest position not yet cleared or reserved by someone else. A soldier clears a position by
 * reaching it (within 1.5 m). An ended movement command retries after six seconds without progress;
 * an active movement command gets twenty-five seconds. Each position is retried
 * twice, then records it unreachable while other rooms continue. Timeouts never clear rooms.
 * The order ends after all rooms are visited or attempted, or after 240 s; the squad rejoins formation. The group is set to COMBAT for the clear, and its previous
 * behaviour is restored afterwards. While clearing, the squad does not flank, retreat or search, and
 * is not sent to reinforce others.
 * With LAMBS Waypoints loaded and Waldo_AIPass_LambsMode "SPLIT", the order is handed to
 * lambs_wp_fnc_taskCQB instead (disable with the "useLambs" option). The WMP clear needs the Smart AI
 * Pass running (Waldo_AIPass_Enable); the LAMBS hand-over does not.
 * Locality and authority: call where the group is local, or on the server, which forwards to the
 * owner. Non-server, non-owner copies do nothing.
 *
 * Review contract: Local job generations prevent replaced jobs from issuing orders. Eligibility is checked before dispatch and on each step. Public visited and unreachable position indices, retry counts, deadline and original behaviour survive handover; local movement assignments are rebuilt.
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
 * [group this, nearestBuilding this] call Waldo_fnc_CortexClearBuilding;
 * Result: the squad works through every room of the building.
 *
 * Current callers: mission scripts and the AI Orders ZEN module.
 */

params [["_group", grpNull, [grpNull, objNull]], ["_target", objNull, [objNull, []]], ["_options", createHashMap, [createHashMap]]];
if (_group isEqualType objNull) then {_group = group _group};
if (isNull _group) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!local _group) exitWith {
    if (isServer) then {[_group, _target, _options] remoteExecCall ["Waldo_fnc_CortexClearBuilding", groupOwner _group]; true} else {false};
};
if !([_group] call Waldo_fnc_CortexIsEligible) exitWith {false};
private _building = if (_target isEqualType objNull) then {_target} else {nearestBuilding _target};
if (isNull _building) exitWith {if (_options getOrDefault ["resume", false]) then {[_group] call Waldo_fnc_CortexClearRelease}; false};
if ((_options getOrDefault ["useLambs", true]) && {isClass (configFile >> "CfgPatches" >> "lambs_wp")}
    && {toUpperANSI (missionNamespace getVariable ["Waldo_AIPass_LambsMode", "SPLIT"]) == "SPLIT"}) exitWith {
    [_group,false] call Waldo_fnc_CortexReleaseGroup;
    [_group] call Waldo_fnc_CortexClearRelease;
    if ((_group getVariable ["Waldo_AIPass_Garrison",[]]) isNotEqualTo []) then {[_group] call Waldo_fnc_CortexGarrisonRelease};
    if ((_group getVariable ["Waldo_AIPass_Defend",[]]) isNotEqualTo []) then {[_group] call Waldo_fnc_CortexDefendRelease};
    [_group, getPosATL _building, _options getOrDefault ["radius", 50]] spawn lambs_wp_fnc_taskCQB;
    diag_log format ["[WMP CORTEX] %1 clear building handed to LAMBS (%2)", _group, typeOf _building];
    true
};
if !(missionNamespace getVariable ["Waldo_AIPass_Active", false]) exitWith {
    diag_log format ["[WMP CORTEX] %1 clear building refused: the Smart AI Pass is not running on this machine.", _group];
    false
};
private _positions = _building buildingPos -1;
if (_positions isEqualTo []) exitWith {false};
private _leader = leader _group;
private _available = (units _group) select {alive _x && {local _x} && {!isPlayer _x} && {lifeState _x != "INCAPACITATED"} && {vehicle _x == _x}};
private _team = if (count _available <= 2) then {_available} else {_available select {_x != _leader}};
if (_team isEqualTo []) exitWith {false};
[_group,false] call Waldo_fnc_CortexReleaseGroup;
if ((_group getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo []) then {[_group] call Waldo_fnc_CortexGarrisonRelease};
if ((_group getVariable ["Waldo_AIPass_Defend", []]) isNotEqualTo []) then {[_group] call Waldo_fnc_CortexDefendRelease};
private _previous = _group getVariable ["Waldo_AIPass_ClearOrder", []];
private _resume = _options getOrDefault ["resume", false] && {_previous isNotEqualTo []} && {(_previous select 0) == _building};
private _baseBehaviour = if (_previous isEqualTo []) then {behaviour _leader} else {_previous select 3};
private _cleared = if (_resume) then {+(_previous select 1)} else {[]};
private _unreachable = if (_resume) then {+(_previous param [4, []])} else {[]};
private _retryCounts = if (_resume) then {+(_previous param [5, []])} else {[]};
private _deadline = if (_resume) then {_previous select 2} else {serverTime + 240};
if (serverTime >= _deadline) exitWith {[_group] call Waldo_fnc_CortexClearRelease; false};
// Replacing a clear must retire its engine movement orders as well as its queued job.
// Validate the new building/team first; an invalid request must preserve the current order.
// HC resume keeps the published progress/deadline rather than starting a new episode.
if (!_resume && {_previous isNotEqualTo []}) then {[_group] call Waldo_fnc_CortexClearRelease};
_group setVariable ["Waldo_AIPass_ClearOrder", [_building, _cleared, _deadline, _baseBehaviour, _unreachable, _retryCounts], true];
_group setVariable ["Waldo_AIPass_ClearApplied", true];
_group setVariable ["Waldo_Cortex_ClearResult",["RUNNING",count _cleared,count _positions],true];
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
            {if (alive _x && {local _x} && {!isPlayer _x} && {lifeState _x != "INCAPACITATED"} && {group _x == _group} && {_x != _leader}) then {_x doFollow _leader}} forEach (_job get "team");
            if (behaviour _leader == "COMBAT") then {_group setBehaviour (_job get "baseBehaviour")};
            _group setVariable ["Waldo_AIPass_ClearBuilding", nil, true];
            _group setVariable ["Waldo_AIPass_ClearOrder", nil, true];
            _group setVariable ["Waldo_AIPass_ClearApplied", nil];
        };
        private _result = ["INCOMPLETE","COMPLETE"] select (count (_job get "cleared") == count (_job get "positions"));
        _group setVariable ["Waldo_Cortex_ClearResult",[_result,count (_job get "cleared"),count (_job get "positions")],true];
        diag_log format ["[WMP CORTEX] %1 clear building %2 (%3 of %4 positions)",_group,_result,count (_job get "cleared"),count (_job get "positions")];
        -1
    };
    if (isNull _group || {!local _group} || {!(_group getVariable ["Waldo_AIPass_ClearBuilding", false])}
        || {!alive (_job get "building")} || {!(missionNamespace getVariable ["Waldo_AIPass_Active", false])}
        || {!([_group] call Waldo_fnc_CortexIsEligible)}) exitWith {call _finish};
    private _positions = _job get "positions";
    private _cleared = _job get "cleared";
    // Per member: [] or [positionIndex, lastProgressAt, lastPosition, retries].
    private _unreachable = _job get "unreachable";
    private _assigned = _job get "assigned";
    private _retryCounts = _job get "retryCounts";
    private _retryChanged = false;
    // Release reservations before selection so another soldier can visit a casualty's room.
    // Reassigned units belong to their new commander and must receive no further orders here.
    {
        if (!alive _x || {!local _x} || {isPlayer _x} || {lifeState _x == "INCAPACITATED"} || {group _x != _group} || {vehicle _x != _x}) then {
            _assigned set [_forEachIndex,[]];
        };
    } forEach (_job get "team");
    private _now = time;
    private _before = count _cleared;
    private _unreachableBefore = count _unreachable;
    // A worker may physically traverse another assigned position on the way to its own.
    // Record that observed visit too; assignment ownership is not evidence of clearance.
    {
        private _visitor = _x;
        if (alive _visitor && {local _visitor} && {!isPlayer _visitor}
            && {lifeState _visitor != "INCAPACITATED"} && {group _visitor == _group}
            && {vehicle _visitor == _visitor}) then {
            private _actual = getPosASL _visitor;
            {
                if !(_forEachIndex in _cleared) then {
                    if (_actual vectorDistance (AGLToASL _x) <= 1.5) then {
                        _cleared pushBackUnique _forEachIndex;
                        private _failedIndex = _unreachable find _forEachIndex;
                        if (_failedIndex >= 0) then {_unreachable deleteAt _failedIndex};
                    };
                };
            } forEach _positions;
        };
    } forEach (_job get "team");
    {
        private _unit = _x;
        private _member = _forEachIndex;
        if (alive _unit && {local _unit} && {!isPlayer _unit} && {lifeState _unit != "INCAPACITATED"} && {group _unit == _group} && {vehicle _unit == _unit}) then {
            [_unit,_job get "building"] call Waldo_fnc_CortexBuildingDoor;
            private _current = _assigned select _member;
            if (_current isNotEqualTo []) then {
                _current params ["_index", "_since", "_lastPosition", "_retries"];
                // Building positions are AGL; compare in ASL so upper floors and slopes measure true.
                if (_index in _cleared) then {
                    _cleared pushBackUnique _index;
                    _assigned set [_member, []];
                    _current = [];
                } else {
                    if (_unit distance _lastPosition >= 1) then {
                        _current set [1,_now];
                        _current set [2,getPosATL _unit];
                    } else {
                        // Recover a discarded/completed engine command sooner than an active path.
                        // Moving soldiers retain the longer navigation allowance.
                        private _commandEnded = currentCommand _unit in ["", "STOP"];
                        private _retryDelay = [25,6] select _commandEnded;
                        if (_now - _since > _retryDelay) then {
                            if (_retries < 2) then {
                                _unit doMove (_positions select _index);
                                _current set [1,_now];
                                _current set [3,_retries+1];
                                _retryCounts set [_index,_retries+1];
                                _retryChanged = true;
                            } else {
                                _unreachable pushBackUnique _index;
                                diag_log format ["[WMP CORTEX] %1 clear room unreachable index=%2 unit=%3 remaining=%4",_group,_index,_unit,_unit distance (_positions select _index)];
                                _assigned set [_member,[]];
                                _current=[];
                            };
                        };
                    };
                };
            };
            if (_current isEqualTo []) then {
                private _taken = (_assigned select {_x isNotEqualTo []}) apply {_x select 0};
                private _best = -1;
                private _bestDistance = 1e6;
                {
                    if !(_forEachIndex in _cleared || {_forEachIndex in _taken} || {_forEachIndex in _unreachable}) then {
                        private _distance = (getPosASL _unit) vectorDistance (AGLToASL _x);
                        if (_distance < _bestDistance) then {_best = _forEachIndex; _bestDistance = _distance};
                    };
                } forEach _positions;
                if (_best >= 0) then {
                    // Break formation once per worker, not at every interior destination.
                    // Repeated STOP orders interrupt otherwise continuous traversal.
                    private _started = _job get "started";
                    if !(_unit in _started) then {doStop _unit; _started pushBack _unit};
                    _unit doMove (_positions select _best);
                    _assigned set [_member, [_best, _now, getPosATL _unit, _retryCounts param [_best,0]]];
                };
            };
        };
    } forEach (_job get "team");
    if (count _cleared != _before || {count _unreachable != _unreachableBefore} || {_retryChanged}) then {
        _group setVariable ["Waldo_AIPass_ClearOrder", [_job get "building", +_cleared, _job get "deadline", _job get "baseBehaviour", +_unreachable, +_retryCounts], true];
    };
    if ((count _cleared + count _unreachable) >= count _positions || {serverTime > (_job get "deadline")} || {(_job get "team") findIf {alive _x && {local _x} && {!isPlayer _x} && {lifeState _x != "INCAPACITATED"} && {group _x == _group} && {vehicle _x == _x}} < 0}) exitWith {call _finish};
    1.5
}, createHashMapFromArray [
    ["group", _group], ["team", _team], ["started", []], ["positions", _positions], ["cleared", _cleared], ["building", _building], ["assigned", _team apply {[]}], ["unreachable",_unreachable], ["retryCounts",_retryCounts],
    ["deadline", _deadline], ["baseBehaviour", _baseBehaviour], ["generation", _generation]
], 0] call Waldo_fnc_CortexQueueJob;
diag_log format ["[WMP CORTEX] %1 clearing %2 (%3 positions, %4 soldiers)", _group, typeOf _building, count _positions, count _team];
true

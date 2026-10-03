/*
 * Author: WaldoTheWarfighter
 * Orders an AI group to clear a building room by room.
 *
 * Every available soldier, including the leader, may join the clear up to the building's bounded entry
 * capacity. Each interior worker owns one movement lane and draws the nearest unclaimed room from a
 * shared low-floor-first queue. Only roofed interior positions are clearance objectives; exposed
 * balconies and roof posts belong to garrisoning. This avoids a support partner waiting outside while only one soldier
 * attempts every room, and makes a large squad flow through the building instead of parking around it.
 * Spare members above the entry capacity remain an actual reserve. A worker tries its room directly
 * first, then uses a bounded set of alternate real entrances only after the direct route stalls. A
 * blocked room returns to the shared queue for another worker before it can be marked unreachable.
 * As in LAMBS CQB, committed units move upright at a bounded assault speed; unlike LAMBS, Cortex
 * records a room only after a physical 1.5 m visit and never teleports a stuck soldier or clears a
 * room from outside. A position is visited only when a soldier physically reaches it within
 * 1.5 m. A casualty or incapacitation is replaced from the uncommitted reserve; without a replacement,
 * other active workers continue claiming the remaining rooms. Timeouts never clear rooms.
 * After all rooms are visited or attempted, the clearing element exits through the building entry
 * to an exterior release point before formation control is restored. This explicit egress avoids
 * abandoning soldiers on interior path nodes and provides the same entry-through-exit primitive used
 * by later movement actions. The order has a progress-renewed safety lease rather than a fixed
 * performance deadline. It preserves the group's current behaviour and combat mode: aware squads
 * remain responsive to the route, while squads already fighting keep engaging. Cleanup therefore
 * cannot overwrite a later contact or Zeus behaviour change. While clearing, the squad does not
 * flank, retreat or search, and
 * is not sent to reinforce others.
 * With LAMBS Waypoints loaded, its public taskCQB controller is the primary backend regardless of
 * the broader Danger FSM ownership mode (disable with the "useLambs" option). Cortex retains the
 * spawned task handle and semantic intent so Zeus, stop and locality migration can release or replay
 * it cleanly. The WMP fallback needs the Smart AI Pass running; the LAMBS hand-over does not.
 * Locality and authority: call where the group is local, or on the server, which forwards to the
 * owner. Non-server, non-owner copies do nothing.
 *
 * Review contract: Local job generations prevent replaced jobs from issuing orders. Eligibility is checked before dispatch and on each step. Public visited and unreachable position indices, retry/failure evidence, progress-renewed deadline and original behaviour survive handover; local movement assignments are rebuilt.
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
 * Result: an entry element attempts successive building positions; unreachable positions leave an INCOMPLETE result.
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
if ((_options getOrDefault ["useLambs", true]) && {isClass (configFile >> "CfgPatches" >> "lambs_wp")}) exitWith {
    [_group,false] call Waldo_fnc_CortexReleaseGroup;
    [_group] call Waldo_fnc_CortexClearRelease;
    if ((_group getVariable ["Waldo_AIPass_Garrison",[]]) isNotEqualTo []) then {[_group] call Waldo_fnc_CortexGarrisonRelease};
    if ((_group getVariable ["Waldo_AIPass_Defend",[]]) isNotEqualTo []) then {[_group] call Waldo_fnc_CortexDefendRelease};
    [_group,"CQB",_building,_options getOrDefault ["radius",50]] call Waldo_fnc_CortexLambsBuildingStart
};
if !(missionNamespace getVariable ["Waldo_AIPass_Active", false]) exitWith {
    diag_log format ["[WMP CORTEX] %1 clear building refused: the Smart AI Pass is not running on this machine.", _group];
    false
};
private _allPositions = _building buildingPos -1;
private _positions = _allPositions select {
    private _positionASL=AGLToASL _x;
    (lineIntersectsSurfaces [_positionASL vectorAdd [0,0,0.5],_positionASL vectorAdd [0,0,10],objNull,objNull,true,1]) isNotEqualTo []
};
if (_positions isEqualTo []) then {_positions=+_allPositions};
if (_positions isEqualTo []) exitWith {false};
private _leader = leader _group;
private _available = (units _group) select {alive _x && {local _x} && {!isPlayer _x} && {lifeState _x != "INCAPACITATED"} && {vehicle _x == _x}};
private _team = +_available;
if (_team isEqualTo []) exitWith {false};
// A small building needs an entry element, not one soldier parked at every slot.
// Leave spare squad members with their leader; bound interior workers by available space.
// Keeping fewer workers than positions lets each worker advance through successive positions.
private _entryCapacity = ((((count _positions) min 4) * 2) max 2) min 8;
_team = _team select [0,_entryCapacity];
[_group,false] call Waldo_fnc_CortexReleaseGroup;
if ((_group getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo []) then {[_group] call Waldo_fnc_CortexGarrisonRelease};
if ((_group getVariable ["Waldo_AIPass_Defend", []]) isNotEqualTo []) then {[_group] call Waldo_fnc_CortexDefendRelease};
private _previous = _group getVariable ["Waldo_AIPass_ClearOrder", []];
private _resume = _options getOrDefault ["resume", false] && {_previous isNotEqualTo []} && {(_previous select 0) == _building};
private _baseBehaviour = if (_previous isEqualTo []) then {behaviour _leader} else {_previous select 3};
private _cleared = if (_resume) then {+(_previous select 1)} else {[]};
private _unreachable = if (_resume) then {+(_previous param [4, []])} else {[]};
private _retryCounts = if (_resume) then {+(_previous param [5, []])} else {[]};
private _failedBy = if (_resume) then {+(_previous param [6, _positions apply {[]}])} else {_positions apply {[]}};
if (count _failedBy != count _positions) then {_failedBy = _positions apply {[]}};
private _lastProgressAt = if (_resume) then {_previous param [7,serverTime]} else {serverTime};
private _deadline = if (_resume) then {_previous select 2} else {serverTime + 240};
if (serverTime >= _deadline) exitWith {[_group] call Waldo_fnc_CortexClearRelease; false};
// Replacing a clear must retire its engine movement orders as well as its queued job.
// Validate the new building/team first; an invalid request must preserve the current order.
// HC resume keeps the published progress/deadline rather than starting a new episode.
if (!_resume && {_previous isNotEqualTo []}) then {[_group] call Waldo_fnc_CortexClearRelease};
_group setVariable ["Waldo_AIPass_ClearOrder", [_building, _cleared, _deadline, _baseBehaviour, _unreachable, _retryCounts, _failedBy, _lastProgressAt], true];
_group setVariable ["Waldo_AIPass_ClearApplied", true];
_group setVariable ["Waldo_Cortex_ClearResult",["RUNNING",count _cleared,count _positions],true];
_group setVariable ["Waldo_Cortex_ClearEvidence",nil,true];
_group setVariable ["Waldo_Cortex_ClearReinforcements",[],true];
private _generation = (_group getVariable ["Waldo_AIPass_ClearGeneration", 0]) + 1;
_group setVariable ["Waldo_AIPass_ClearGeneration", _generation];
_group setVariable ["Waldo_AIPass_ClearBuilding", true, true];
private _entries=[];
for "_exitIndex" from 0 to 15 do {
    private _candidate=_building buildingExit _exitIndex;
    if (_candidate isNotEqualTo [0,0,0] && {_candidate distance2D _building < 50}
        && {_entries findIf {_x distance2D _candidate < 1} < 0}) then {
        _entries pushBack _candidate;
    };
};
if (_entries isNotEqualTo []) then {
    private _entryOrigin=getPosATL leader _group;
    _entries=[_entries,[],{_x distance2D _entryOrigin},"ASCEND"] call BIS_fnc_sortBy;
    _entries resize ((count _entries) min 4);
};
private _entryRoute=if (_entries isEqualTo []) then {[]} else {
    private _centroid=[0,0,0];
    {_centroid=_centroid vectorAdd getPosATL _x} forEach _team;
    _centroid=_centroid vectorMultiply (1/(count _team));
    private _ranked=_entries apply {[_centroid distance2D _x,_x]};
    _ranked sort true;
    +((_ranked select 0) select 1)
};
// Build a stable continuous route rather than repeatedly choosing whichever marker is nearest
// to each individual. This prevents criss-crossing and gives every pair a clear-through sector.
private _routeOrder=[];
private _remaining=[];
for "_index" from 0 to ((count _positions)-1) do {
    if !(_index in (_cleared+_unreachable)) then {_remaining pushBack _index};
};
private _routeCursor=if (_entryRoute isEqualTo []) then {getPosATL _building} else {_entryRoute};
while {_remaining isNotEqualTo []} do {
    private _lowest=1e9;
    {private _height=(_positions select _x) select 2; if (_height < _lowest) then {_lowest=_height}} forEach _remaining;
    private _floorCandidates=_remaining select {abs (((_positions select _x) select 2)-_lowest) < 1.8};
    private _bestSlot=0;
    private _bestDistance=1e9;
    {
        private _distance=_routeCursor distance2D (_positions select _x);
        if (_distance < _bestDistance) then {_bestSlot=_remaining find _x; _bestDistance=_distance};
    } forEach _floorCandidates;
    private _positionIndex=_remaining deleteAt _bestSlot;
    _routeOrder pushBack _positionIndex;
    _routeCursor=_positions select _positionIndex;
};
// One worker per lane lets every committed soldier enter and traverse rooms. A former two-person
// point/support lane left half of each element outside and could stall the whole clear behind one
// engine path. Workers still share claims and failure evidence, so they do not crowd one room.
private _pairs=_team apply {[_x]};
private _pairRoutes=_pairs apply {[]};
private _pending=+_routeOrder;
private _pairStates=[];
{
    private _pair=_x;
    private _pairLead=_pair select 0;
    private _entryIndex=-1;
    if (_entries isNotEqualTo []) then {
        private _ranked=_entries apply {[_pairLead distance2D _x,_forEachIndex]};
        _ranked sort true;
        _entryIndex=(_ranked select 0) select 1;
    };
    _pairStates pushBack [0,false,_pair apply {getPosATL _x},time,0,-1,
        time+(_forEachIndex*1.25),0,-1,_entryIndex,[],0,false];
} forEach _pairs;
[{
    params ["_job"];
    private _group = _job get "group";
    if (isNull _group || {!local _group}) exitWith {-1};
    if ((_group getVariable ["Waldo_AIPass_ClearGeneration", -1]) != (_job get "generation")) exitWith {-1};
    private _finish = {
        params [["_restore",true,[true]]];
        _group setVariable ["Waldo_Cortex_ClearEvidence",[+(_job get "cleared"),+(_job get "unreachable"),+(_job get "retryCounts"),+(_job get "failedBy"),_job get "deadline",_job get "lastProgressAt"],true];
        if (!isNull _group) then {
            private _leader = leader _group;
            {
                if (local _x && {!isPlayer _x} && {group _x == _group}) then {
                    if (alive _x && {lifeState _x != "INCAPACITATED"}) then {
                        if (unitPos _x == "UP" && {!isNil {_x getVariable "Waldo_Cortex_ClearStance"}}) then {
                            _x setUnitPos (_x getVariable ["Waldo_Cortex_ClearStance","AUTO"]);
                        };
                        if (getForcedSpeed _x == 4 && {!isNil {_x getVariable "Waldo_Cortex_ClearForcedSpeed"}}) then {
                            _x forceSpeed (_x getVariable ["Waldo_Cortex_ClearForcedSpeed",-1]);
                        };
                        if (_restore) then {
                        _x doWatch objNull;
                        _x doFollow _leader;
                        };
                    };
                    _x setVariable ["Waldo_Cortex_ClearForcedSpeed",nil];
                    _x setVariable ["Waldo_Cortex_ClearStance",nil];
                };
            } forEach (_job get "team");
            _group setVariable ["Waldo_AIPass_ClearBuilding", nil, true];
            _group setVariable ["Waldo_Cortex_ClearEgress",nil,true];
            _group setVariable ["Waldo_AIPass_ClearOrder", nil, true];
            _group setVariable ["Waldo_AIPass_ClearApplied", nil];
        };
        private _result = ["INCOMPLETE","COMPLETE"] select (count (_job get "cleared") == count (_job get "positions") && {!(_job getOrDefault ["egressFailed",false])});
        _group setVariable ["Waldo_Cortex_ClearResult",[_result,count (_job get "cleared"),count (_job get "positions")],true];
        diag_log format ["[WMP CORTEX] %1 clear building %2 (%3 of %4 positions)",_group,_result,count (_job get "cleared"),count (_job get "positions")];
        -1
    };
    if (isNull _group || {!local _group} || {!(_group getVariable ["Waldo_AIPass_ClearBuilding", false])}
        || {!alive (_job get "building")} || {!(missionNamespace getVariable ["Waldo_AIPass_Active", false])}) exitWith {[true] call _finish};
    // A fresh Zeus or script order immediately owns movement. Retire Cortex state without
    // a follow, stance or behaviour command that could overwrite that replacement order.
    if !([_group] call Waldo_fnc_CortexIsEligible) exitWith {[false] call _finish};
    if ((_job getOrDefault ["phase","CLEAR"]) == "EGRESS") exitWith {
        private _assignments=(_job get "egressAssignments") select {
            _x params ["_unit"];
            alive _unit && {local _unit} && {!isPlayer _unit} && {lifeState _unit != "INCAPACITATED"}
                && {group _unit == _group} && {vehicle _unit == _unit}
        };
        private _arrived=_assignments findIf {(_x select 0) distance2D (_x select 1) > 5} < 0;
        if (_arrived || {_assignments isEqualTo []} || {time >= (_job get "egressDeadline")}) then {
            if (!_arrived && {_assignments isNotEqualTo []}) then {
                _job set ["egressFailed",true];
                diag_log format ["[WMP CORTEX] %1 clear egress incomplete (%2 still inside)",_group,{(_x select 0) distance2D (_x select 1) > 5} count _assignments];
            };
            [true] call _finish
        } else {
            {
                _x params ["_unit","_target"];
                private _openedDoor=[_unit,_job get "building"] call Waldo_fnc_CortexBuildingDoor;
                if (_openedDoor || {currentCommand _unit in ["","STOP"]} || {time >= (_job get "egressReissue")}) then {
                    _unit doMove _target;
                    _unit setDestination [_target,"LEADER PLANNED",true];
                };
            } forEach _assignments;
            if (time >= (_job get "egressReissue")) then {_job set ["egressReissue",time+6]};
            1.5
        }
    };
    private _positions = _job get "positions";
    private _cleared = _job get "cleared";
    private _unreachable = _job get "unreachable";
    private _assigned = _job get "assigned";
    private _retryCounts = _job get "retryCounts";
    private _failedBy = _job get "failedBy";
    private _retryChanged = false;
    private _pairs=_job get "pairs";
    private _pairStates=_job get "pairStates";
    // Refill casualties from soldiers that were deliberately left on exterior security. This is
    // evaluated in the existing building job, so it adds no per-unit scheduler or event-handler cost.
    private _reserved=[];
    {_reserved append _x} forEach _pairs;
    private _leader=leader _group;
    private _rotatedOut=_job getOrDefault ["rotatedOut",[]];
    private _reserves=(units _group) select {
        alive _x && {local _x} && {!isPlayer _x} && {lifeState _x != "INCAPACITATED"}
        && {vehicle _x == _x} && {!(_x in _reserved)} && {!(_x in _rotatedOut)} && {_x != _leader}
    };
    if (_reserves isEqualTo [] && {alive _leader} && {local _leader} && {!isPlayer _leader}
        && {lifeState _leader != "INCAPACITATED"} && {vehicle _leader == _leader} && {!(_leader in _reserved)}) then {
        _reserves pushBack _leader;
    };
    {
        private _pairIndex=_forEachIndex;
        private _pair=_x;
        private _state=_pairStates select _pairIndex;
        for "_slot" from 0 to ((count _pair)-1) do {
            private _member=_pair select _slot;
            if ((!alive _member || {!local _member} || {isPlayer _member} || {lifeState _member == "INCAPACITATED"}
                || {group _member != _group} || {vehicle _member != _member}) && {_reserves isNotEqualTo []}) then {
                private _replacement=_reserves deleteAt 0;
                _pair set [_slot,_replacement];
                private _team=_job get "team";
                _team pushBackUnique _replacement;
                (_job get "assigned") pushBack [];
                private _lastPositions=_state select 2;
                _lastPositions set [_slot,getPosATL _replacement];
                _state set [2,_lastPositions];
                _state set [3,time];
                _state set [4,0];
                _state set [5,-1];
                private _evidence=_group getVariable ["Waldo_Cortex_ClearReinforcements",[]];
                _evidence pushBack [serverTime,netId _member,netId _replacement,_pairIndex,_slot];
                _group setVariable ["Waldo_Cortex_ClearReinforcements",_evidence,true];
                diag_log format ["[WMP CORTEX] Clear pair %1 reinforced: %2 replaced %3",_pairIndex,_replacement,_member];
            };
        };
    } forEach _pairs;
    // Release reservations before selection so another soldier can visit a casualty's room.
    // Reassigned units belong to their new commander and must receive no further orders here.
    private _activeWorkers=(_job get "team") select {alive _x && {local _x} && {!isPlayer _x}
        && {lifeState _x != "INCAPACITATED"} && {group _x == _group} && {vehicle _x == _x}};
    private _failureThreshold=(count (_job get "pairs")) min 2 max 1;
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
                        private _pendingIndex = (_job get "pending") find _forEachIndex;
                        if (_pendingIndex >= 0) then {(_job get "pending") deleteAt _pendingIndex};
                        _failedBy set [_forEachIndex,[]];
                    };
                };
            } forEach _positions;
        };
    } forEach (_job get "team");
    private _pairRoutes=_job get "pairRoutes";
    {
        private _pairIndex=_forEachIndex;
        private _pair=_x select {alive _x && {local _x} && {!isPlayer _x} && {lifeState _x != "INCAPACITATED"} && {group _x == _group} && {vehicle _x == _x}};
        if (_pair isEqualTo []) then {
            private _state=_pairStates select _pairIndex;
            private _route=_pairRoutes select _pairIndex;
            private _cursor=_state select 0;
            if (_cursor < count _route) then {
                private _abandoned=_route select _cursor;
                if !(_abandoned in (_cleared+_unreachable)) then {(_job get "pending") pushBackUnique _abandoned};
                _state set [0,count _route];
            };
        };
        if (_pair isNotEqualTo []) then {
            private _state=_pairStates select _pairIndex;
            _state params ["_cursor","_approachingEntry","_lastPositions","_lastProgress","_retries","_lastTarget","_startAt","_moverIndex","_previousPositionIndex","_entryIndex","_triedEntries","_roomsCleared","_entered"];
            if (_now >= _startAt) then {
                private _route=_pairRoutes select _pairIndex;
                while {_cursor < count _route && {(_route select _cursor) in (_cleared+_unreachable)}} do {_cursor=_cursor+1};
                // Claim the nearest room that this pair has not already failed. Claims are removed
                // from the shared queue immediately, preventing several pairs from crowding one node.
                if (_cursor >= count _route) then {
                    private _pending=_job get "pending";
                    private _pairId=format ["PAIR_%1",_pairIndex];
                    private _candidates=_pending select {!(_pairId in (_failedBy select _x))};
                    if (_candidates isNotEqualTo []) then {
                        private _point=_pair select (_moverIndex mod count _pair);
                        private _ranked=_candidates apply {
                            private _candidate=_positions select _x;
                            [(_point distance2D _candidate)+(abs (((getPosATL _point) select 2)-(_candidate select 2))*2.5),_x]
                        };
                        _ranked sort true;
                        private _claimed=(_ranked select 0) select 1;
                        _pending deleteAt (_pending find _claimed);
                        _route pushBack _claimed;
                        _cursor=(count _route)-1;
                        _lastTarget=-1;
                        _retries=0;
                        _triedEntries=[];
                        _entryIndex=-1;
                        if ((_job get "entries") isNotEqualTo []) then {
                            private _entryRanks=(_job get "entries") apply {[_point distance2D _x,_forEachIndex]};
                            _entryRanks sort true;
                            _entryIndex=(_entryRanks select 0) select 1;
                        };
                        // Distant interior targets can leave Arma planning without moving. Stage at
                        // the nearest real entrance first, then commit through it. Workers already
                        // near the building keep the faster direct route.
                        private _entryTarget=if (_entryIndex >= 0) then {(_job get "entries") select _entryIndex} else {[]};
                        private _entryProbe=_pair select (_moverIndex mod count _pair);
                        _approachingEntry=_entryTarget isNotEqualTo [] && {_entryProbe distance2D _entryTarget > 8};
                    };
                };
                if (_cursor < count _route) then {
                    private _positionIndex=_route select _cursor;
                    private _entryTarget=if (_entryIndex >= 0 && {_entryIndex < count (_job get "entries")}) then {
                        (_job get "entries") select _entryIndex
                    } else {[]};
                    if (_approachingEntry && {_entryTarget isNotEqualTo []} && {_pair findIf {_x distance2D _entryTarget <= 3} >= 0}) then {
                        _approachingEntry=false;
                        _entered=true;
                        _triedEntries pushBackUnique _entryIndex;
                        _lastTarget=-1;
                        _retries=0;
                    };
                    private _target=[_positions select _positionIndex,_entryTarget] select _approachingEntry;
                    private _issue=_lastTarget != _positionIndex;
                    private _point=_pair select (_moverIndex mod count _pair);
                    private _supportTarget=[];
                    if (count _pair > 1) then {
                        _supportTarget=if (_approachingEntry) then {
                            private _outward=(getPosATL (_job get "building")) getDir _entryTarget;
                            _entryTarget getPos [3,_outward]
                        } else {
                            if (_previousPositionIndex >= 0) then {_positions select _previousPositionIndex} else {_entryTarget}
                        };
                        if (_supportTarget isEqualTo []) then {
                            private _outward=(getPosATL (_job get "building")) getDir _target;
                            _supportTarget=_target getPos [2.5,_outward];
                        };
                    };
                    {
                        private _unit=_x;
                        private _openedDoor=[_unit,_job get "building"] call Waldo_fnc_CortexBuildingDoor;
                        if (_issue || {_openedDoor}) then {
                            private _started=_job get "started";
                            if !(_unit in _started) then {
                                doStop _unit;
                                _unit setVariable ["Waldo_Cortex_ClearStance",unitPos _unit];
                                _unit setVariable ["Waldo_Cortex_ClearForcedSpeed",getForcedSpeed _unit];
                                _unit setUnitPos "UP";
                                _unit forceSpeed 4;
                                _started pushBack _unit;
                            };
                            private _unitTarget=if (_unit == _point || {_supportTarget isEqualTo []}) then {_target} else {_supportTarget};
                            _unit doMove _unitTarget;
                            _unit setDestination [_unitTarget,"LEADER PLANNED",true];
                        };
                        _assigned set [(_job get "team") find _unit,[_positionIndex,_lastProgress,getPosATL _unit,_retries,_approachingEntry]];
                    } forEach _pair;
                    if (_issue) then {_lastTarget=_positionIndex; _lastProgress=_now; _lastPositions=_pair apply {getPosATL _x}};
                    private _moved=false;
                    {
                        private _old=_lastPositions param [_forEachIndex,getPosATL _x];
                        if (_x distance2D _old >= 1) then {_moved=true};
                    } forEach _pair;
                    if (_moved) then {
                        _lastPositions=_pair apply {getPosATL _x};
                        _lastProgress=_now;
                        _job set ["deadline",(_job get "deadline") max (serverTime+120)];
                        _job set ["lastProgressAt",serverTime];
                    };
                    if (_positionIndex in _cleared) then {
                        _previousPositionIndex=_positionIndex;
                        _cursor=_cursor+1;
                        _roomsCleared=_roomsCleared+1;
                        // Reserves replace casualties only. Routine rotation previously pulled a
                        // successful worker out mid-clear and introduced a new actor at the doorway,
                        // creating pauses and exterior congestion without improving room coverage.
                        if (count _pair > 1) then {_moverIndex=(_moverIndex+1) mod count _pair};
                        _lastTarget=-1;
                        _retries=0;
                        _lastProgress=_now;
                    } else {
                        private _commandEnded=_pair findIf {currentCommand _x in ["","STOP"]} >= 0;
                        private _retryDelay=[25,6] select _commandEnded;
                        if (_now-_lastProgress > _retryDelay) then {
                            if (_retries < 3) then {
                                {
                                    private _unitTarget=if (_x == _point || {_supportTarget isEqualTo []}) then {_target} else {_supportTarget};
                                    _x doMove _unitTarget;
                                    _x setDestination [_unitTarget,"LEADER PLANNED",true];
                                } forEach _pair;
                                _retries=_retries+1;
                                _lastProgress=_now;
                                _retryCounts set [_positionIndex,(_retryCounts param [_positionIndex,0])+1];
                            } else {
                                private _changedEntry=false;
                                if (!_entered && {(_job get "entries") isNotEqualTo []}) then {
                                    if (_approachingEntry) then {_triedEntries pushBackUnique _entryIndex};
                                    private _entryRanks=[];
                                    {
                                        if !(_forEachIndex in _triedEntries) then {
                                            _entryRanks pushBack [(_pair select 0) distance2D _x,_forEachIndex];
                                        };
                                    } forEach (_job get "entries");
                                    if (_entryRanks isNotEqualTo []) then {
                                        _entryRanks sort true;
                                        _entryIndex=(_entryRanks select 0) select 1;
                                        _approachingEntry=true;
                                        _lastTarget=-1;
                                        _lastProgress=_now;
                                        _lastPositions=_pair apply {getPosATL _x};
                                        _retries=0;
                                        _changedEntry=true;
                                    };
                                };
                                if (!_changedEntry) then {
                                private _pairId=format ["PAIR_%1",_pairIndex];
                                private _failures=_failedBy select _positionIndex;
                                _failures pushBackUnique _pairId;
                                _failedBy set [_positionIndex,_failures];
                                if (count _failures >= _failureThreshold) then {
                                    _unreachable pushBackUnique _positionIndex;
                                } else {
                                    // Return the room to the shared queue. Another pair must claim it;
                                    // this pair's failure identity prevents an immediate self-retry loop.
                                    (_job get "pending") pushBackUnique _positionIndex;
                                };
                                _cursor=_cursor+1;
                                _lastTarget=-1;
                                _retries=0;
                                _triedEntries=[];
                                };
                            };
                            _retryChanged=true;
                        };
                    };
                    _state set [0,_cursor]; _state set [1,_approachingEntry]; _state set [2,_lastPositions];
                    _state set [3,_lastProgress]; _state set [4,_retries]; _state set [5,_lastTarget];
                    _state set [7,_moverIndex]; _state set [8,_previousPositionIndex];
                    _state set [9,_entryIndex]; _state set [10,_triedEntries];
                    _state set [11,_roomsCleared];
                    _state set [12,_entered];
                };
            };
        };
    } forEach _pairs;
    private _madeProgress=count _cleared != _before || {count _unreachable != _unreachableBefore};
    if (_madeProgress) then {
        // The total lease is a safety net, not a performance assumption. Genuine physical
        // progress renews it so a busy server or delayed HC does not expire a working clear.
        _job set ["lastProgressAt",serverTime];
        _job set ["deadline",(_job get "deadline") max (serverTime+120)];
    };
    if (_madeProgress || {_retryChanged}) then {
        _group setVariable ["Waldo_AIPass_ClearOrder", [_job get "building", +_cleared, _job get "deadline", _job get "baseBehaviour", +_unreachable, +_retryCounts, +_failedBy, _job get "lastProgressAt"], true];
    };
    if ((count _cleared + count _unreachable) >= count _positions || {serverTime > (_job get "deadline")} || {(_job get "team") findIf {alive _x && {local _x} && {!isPlayer _x} && {lifeState _x != "INCAPACITATED"} && {group _x == _group} && {vehicle _x == _x}} < 0}) exitWith {
        private _active=[];
        {_active append _x} forEach (_job get "pairs");
        _active=_active arrayIntersect _active;
        _active=_active select {alive _x && {local _x} && {!isPlayer _x} && {lifeState _x != "INCAPACITATED"}
            && {group _x == _group} && {vehicle _x == _x}};
        private _entries=_job get "entries";
        private _buildingPos=getPosATL (_job get "building");
        private _egressAssignments=_active apply {
            private _unit=_x;
            private _entry=_job get "entry";
            if (_entries isNotEqualTo []) then {
                private _ranked=_entries apply {[_unit distance2D _x,_x]};
                _ranked sort true;
                _entry=+((_ranked select 0) select 1);
            };
            if (_entry isEqualTo []) then {_entry=_buildingPos};
            private _outward=_buildingPos getDir _entry;
            [_unit,_entry getPos [10,_outward]]
        };
        _job set ["phase","EGRESS"];
        _job set ["egressAssignments",_egressAssignments];
        _job set ["egressDeadline",time+45];
        _job set ["egressReissue",time];
        {
            _x params ["_unit","_target"];
            _unit doMove _target;
            _unit setDestination [_target,"LEADER PLANNED",true];
        } forEach _egressAssignments;
        _group setVariable ["Waldo_Cortex_ClearEgress",["EGRESS",_egressAssignments apply {_x select 1},serverTime],true];
        1.5
    };
    1.5
}, createHashMapFromArray [
    ["group", _group], ["team", _team], ["started", []], ["positions", _positions], ["cleared", _cleared], ["building", _building], ["assigned", _team apply {[]}], ["unreachable",_unreachable], ["retryCounts",_retryCounts],
    ["entry",_entryRoute], ["entries",_entries], ["pairs",_pairs], ["pairRoutes",_pairRoutes], ["pairStates",_pairStates], ["pending",_pending],
    ["deadline", _deadline], ["baseBehaviour", _baseBehaviour], ["generation", _generation], ["failedBy",_failedBy], ["lastProgressAt",_lastProgressAt],
    ["phase","CLEAR"],["rotatedOut",[]],["egressAssignments",[]],["egressDeadline",0],["egressReissue",0],["egressFailed",false]
], 0] call Waldo_fnc_CortexQueueJob;
diag_log format ["[WMP CORTEX] %1 clearing %2 (%3 positions, %4 soldiers, %5 entrances)", _group, typeOf _building, count _positions, count _team, count _entries];
true

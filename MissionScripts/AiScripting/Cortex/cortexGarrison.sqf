/*
 * Author: WaldoTheWarfighter
 * Orders an AI group to garrison the buildings around a point.
 *
 * Uses height-sorted, roofed positions and outward watch sectors. PATH locks only after arrival.
 * Defenders duck under fire; local handlers and assignments replay after ownership changes.
 * Positions: building positions within the radius, roofed positions first, then highest first.
 * Each soldier is sent to his own position, then held there with PATH disabled, watching outward.
 * Suppressed or hit, he drops to a lower stance for a few seconds, then stands back up. The order
 * breaks when the group falls to Waldo_AIPass_Garrison_BreakFraction of its strength at the time of
 * the order, or its morale breaks: PATH is re-enabled and the survivors fight normally.
 * With LAMBS Waypoints loaded, its public taskGarrison controller is the primary backend regardless
 * of the broader Danger FSM ownership mode (disable per call with the "useLambs" option). Cortex
 * records the delegated task so Zeus, stop and locality migration can release or replay it cleanly.
 * "inPlace" keeps soldiers where they already stand, for units spawned at building positions (used for
 * Dynamic AO garrisons when Waldo_AIPass_Garrison_DynamicAO is true).
 * The order and each soldier's position are published once as group/unit variables, so a new owner
 * after a headless-client handover re-applies them in its discovery sweep. The WMP garrison needs the
 * Smart AI Pass running (Waldo_AIPass_Enable); the LAMBS hand-over does not.
 * Locality and authority: call where the group is local, or on the server, which forwards to the
 * owner. Non-server, non-owner copies (for example an Eden init field on a client) do nothing.
 *
 * Review contract: Repeated placement releases previous WMP garrison/defence assignments first. The shared eligibility gate rejects player and feature-owned groups before side effects.
 *
 * Arguments:
 * 0: group <GROUP or OBJECT> - the group, or a unit in it
 * 1: centre <ARRAY or OBJECT> - ATL position or object (optional, default: leader position)
 * 2: radius <NUMBER> - search radius in metres (optional, default: 50)
 * 3: options <HASHMAP> (optional) - useLambs (default true), inPlace (default false)
 *
 * Return Value:
 * Boolean - true when the order was applied or forwarded
 *
 * Example:
 * [group this, getPosATL this, 40] call Waldo_fnc_CortexGarrison;
 * Result: the squad occupies the nearby buildings and holds them.
 *
 * Current callers: mission scripts and init fields, the AI Orders ZEN module and Waldo_fnc_CortexDiscover.
 */

params [["_group", grpNull, [grpNull, objNull]], ["_centre", [], [[], objNull]], ["_radius", 50, [0]], ["_options", createHashMap, [createHashMap]]];
if (_group isEqualType objNull) then {_group = group _group};
if (isNull _group) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!local _group) exitWith {
    if (isServer) then {[_group, _centre, _radius, _options] remoteExecCall ["Waldo_fnc_CortexGarrison", groupOwner _group]; true} else {false};
};
if !([_group] call Waldo_fnc_CortexIsEligible) exitWith {false};
if (_centre isEqualType objNull) then {_centre = getPosATL _centre};
if (count _centre < 2) then {_centre = getPosATL leader _group};
private _units = (units _group) select {alive _x && {!isPlayer _x} && {lifeState _x != "INCAPACITATED"} && {vehicle _x == _x}};
if (_units isEqualTo []) exitWith {false};
// Refuse an empty search before releasing the existing order or claiming success.
if (!(_options getOrDefault ["inPlace",false]) && {(nearestObjects [_centre,["House","Building"],_radius,true]) findIf {(_x buildingPos -1) isNotEqualTo []} < 0}) exitWith {false};

if ((_options getOrDefault ["useLambs", true]) && {isClass (configFile >> "CfgPatches" >> "lambs_wp")}) exitWith {
    [_group,false] call Waldo_fnc_CortexReleaseGroup;
    [_group] call Waldo_fnc_CortexClearRelease;
    if ((_group getVariable ["Waldo_AIPass_Garrison",[]]) isNotEqualTo []) then {[_group] call Waldo_fnc_CortexGarrisonRelease};
    if ((_group getVariable ["Waldo_AIPass_Defend",[]]) isNotEqualTo []) then {[_group] call Waldo_fnc_CortexDefendRelease};
    [_group,"GARRISON",_centre,_radius] call Waldo_fnc_CortexLambsBuildingStart
};
if !(missionNamespace getVariable ["Waldo_AIPass_Active", false]) exitWith {
    diag_log format ["[WMP CORTEX] %1 garrison refused: the Smart AI Pass is not running on this machine.", _group];
    false
};

[_group,false] call Waldo_fnc_CortexReleaseGroup;
[_group] call Waldo_fnc_CortexClearRelease;
if ((_group getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo []) then {[_group] call Waldo_fnc_CortexGarrisonRelease};
if ((_group getVariable ["Waldo_AIPass_Defend", []]) isNotEqualTo []) then {[_group] call Waldo_fnc_CortexDefendRelease};
if (_options getOrDefault ["inPlace", false]) then {
    private _candidateAssignments=[];
    {
        private _assignment=[getPosATL _x, _centre getDir _x, objNull];
        _candidateAssignments pushBack _assignment;
        _x setVariable ["Waldo_AIPass_GarrisonPos", _assignment, true];
    } forEach _units;
    _group setVariable ["Waldo_Cortex_GarrisonCandidates",_candidateAssignments,true];
} else {
    private _candidates = [];
    {
        private _building = _x;
        {
            private _positionASL = AGLToASL _x;
            private _roofed = (lineIntersectsSurfaces [_positionASL vectorAdd [0, 0, 1], _positionASL vectorAdd [0, 0, 15], objNull, objNull, true, 1]) isNotEqualTo [];
            _candidates pushBack [[1, 0] select _roofed, -(_x select 2), count _candidates, _x, getPosATL _building, _building];
        } forEach (_building buildingPos -1);
    } forEach (nearestObjects [_centre, ["House", "Building"], _radius, true]);
    _candidates sort true;
    private _candidateAssignments=_candidates apply {[_x select 3,(_x select 4) getDir (_x select 3),_x select 5]};
    _group setVariable ["Waldo_Cortex_GarrisonCandidates",_candidateAssignments,true];
    {
        if (_forEachIndex >= count _candidateAssignments) exitWith {};
        _x setVariable ["Waldo_AIPass_GarrisonPos", _candidateAssignments select _forEachIndex, true];
    } forEach _units;
};
_group setVariable ["Waldo_AIPass_Garrison", [_centre, _radius, count _units], true];
_group setVariable ["Waldo_AIPass_GarrisonApplied", false];
[_group] call Waldo_fnc_CortexGarrisonApplyLocal;
diag_log format ["[WMP CORTEX] %1 garrisoned at %2 r=%3 (%4 soldiers)", _group, _centre, _radius, count _units];
true

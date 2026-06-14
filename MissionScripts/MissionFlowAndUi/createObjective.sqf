/*
 * Author: Waldo
 * Scripting convenience wrapper around the BIS task framework for mission makers
 * who drive objectives from SQF / triggers (not a replacement for the Eden or
 * Zeus task modules). Creates a JIP-safe task, optionally with a persistent map
 * marker at the destination. Runs server-authoritatively so joining players see
 * the task correctly; if called on a client it forwards itself to the server.
 *
 * Arguments:
 * 0: Task ID       <STRING>                       - unique id, used to update the task later
 * 1: Owner         <SIDE/GROUP/OBJECT/ARRAY>      - who receives the task (default: west)
 * 2: Title         <STRING>                       - short task title
 * 3: Description   <STRING>                       - longer description (default: "")
 * 4: Destination   <ARRAY/OBJECT/STRING>          - map position/object (default: [] = none)
 * 5: State         <STRING>                       - CREATED/ASSIGNED/SUCCEEDED/... (default: "ASSIGNED")
 * 6: Create marker <BOOL>                         - drop a persistent map marker at destination (default: true)
 * 7: Task type     <STRING>                       - task icon type (default: "" = default icon)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * ["secure_lz", west, "Secure the LZ", "Clear and hold the landing zone.", getMarkerPos "lz1"] call Waldo_fnc_CreateObjective;
 */

params [
    ["_taskId", "", [""]],
    ["_owner", west, [west, grpNull, objNull, []]],
    ["_title", "New Task", [""]],
    ["_description", "", [""]],
    ["_destination", [], [[], objNull, ""]],
    ["_state", "ASSIGNED", [""]],
    ["_createMarker", true, [true]],
    ["_taskType", "", [""]]
];

if (_taskId isEqualTo "") exitWith {
    diag_log "[WMP] CreateObjective: a non-empty task id is required.";
};

// Keep task creation server-authoritative for correct JIP behaviour.
if (!isServer) exitWith {
    _this remoteExec ["Waldo_fnc_CreateObjective", 2];
};

// description array is [description, title, waypoint marker text]
[_owner, _taskId, [_description, _title, _title], _destination, _state, 1, true, _taskType, true] call BIS_fnc_taskCreate;

// Register the task in the AAR objective ledger (broadcast so the ENDEX debrief, which runs
// client-side, can read it). Ledger entries are [taskId, state].
private _ledger = +(missionNamespace getVariable ["Waldo_AAR_Tasks", []]);
private _at = _ledger findIf {(_x select 0) isEqualTo _taskId};
if (_at < 0) then {
    _ledger pushBack [_taskId, _state];
} else {
    (_ledger select _at) set [1, _state];
};
missionNamespace setVariable ["Waldo_AAR_Tasks", _ledger, true];

// Optional persistent map marker at the destination position.
if (_createMarker && {_destination isEqualType [] && {count _destination >= 2}}) then {
    private _mName = format ["Waldo_obj_%1", _taskId];
    if (markerType _mName == "") then {
        private _m = createMarker [_mName, _destination];
        _m setMarkerType "mil_objective";
        _m setMarkerColor "ColorUNKNOWN";
        _m setMarkerText _title;
    };
};

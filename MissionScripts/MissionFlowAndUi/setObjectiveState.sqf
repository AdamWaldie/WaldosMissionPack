/*
 * Author: Waldo
 * Companion to Waldo_fnc_CreateObjective. Updates a task's state (and tidies up
 * its map marker on completion) without the mission maker touching the BIS task
 * framework directly. Server-authoritative for JIP safety.
 *
 * Arguments:
 * 0: Task ID  <STRING>  - the id passed to Waldo_fnc_CreateObjective
 * 1: State    <STRING>  - SUCCEEDED / FAILED / CANCELED / ASSIGNED / CREATED (default: "SUCCEEDED")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * ["secure_lz", "SUCCEEDED"] call Waldo_fnc_SetObjectiveState;
 */

params [
    ["_taskId", "", [""]],
    ["_state", "SUCCEEDED", [""]]
];

if (_taskId isEqualTo "") exitWith {
    diag_log "[WMP] SetObjectiveState: a non-empty task id is required.";
};

if (!isServer) exitWith {
    _this remoteExec ["Waldo_fnc_SetObjectiveState", 2];
};

[_taskId, _state, true] call BIS_fnc_taskSetState;

// Keep the AAR objective ledger in sync (broadcast for the client-side ENDEX debrief).
private _ledger = +(missionNamespace getVariable ["Waldo_AAR_Tasks", []]);
private _at = _ledger findIf {(_x select 0) isEqualTo _taskId};
if (_at < 0) then {
    _ledger pushBack [_taskId, _state];
} else {
    (_ledger select _at) set [1, _state];
};
missionNamespace setVariable ["Waldo_AAR_Tasks", _ledger, true];

// Remove the helper-created marker once the task is resolved.
if (toUpper _state in ["SUCCEEDED", "FAILED", "CANCELED"]) then {
    private _mName = format ["Waldo_obj_%1", _taskId];
    if (markerType _mName != "") then { deleteMarker _mName; };
};

/*
 * Author: WaldoTheWarfighter
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
    // A state update can legitimately arrive for a task created outside Waldo_fnc_CreateObjective.
    // Preserve a readable fallback title; the ENDEX renderer never exposes the raw ID as though it
    // were mission prose.
    _ledger pushBack [_taskId, "Mission objective", _state];
} else {
    private _entry = _ledger select _at;
    if (count _entry < 3) then {
        // Migrate an old [taskId, state] row without breaking a mission already in progress.
        _entry = [_taskId, "Mission objective", _state];
    } else {
        _entry set [2, _state];
    };
    _ledger set [_at, _entry];
};
missionNamespace setVariable ["Waldo_AAR_Tasks", _ledger, true];

// Remove the helper-created marker once the task is resolved.
if (toUpper _state in ["SUCCEEDED", "FAILED", "CANCELED"]) then {
    private _mName = format ["Waldo_obj_%1", _taskId];
    if (markerType _mName != "") then { deleteMarker _mName; };
};

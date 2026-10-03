/*
 * Author: WaldoTheWarfighter
 * Changes a BIS task state and updates WMP's AAR ledger. Resolved tasks lose their WMP map marker.
 * Locality and authority: client calls forward to the server. BIS task state is JIP-safe; the AAR ledger is
 * public. Repeating a state update replaces that task's ledger state. This call can update a task
 * created elsewhere, but then its new AAR row uses the fallback title "Mission objective".
 * Current callers: mission-maker scripts/triggers; the full-pack audit checks this public API.
 *
 * Arguments:
 * 0: Task ID  <STRING>  - non-empty id passed to Waldo_fnc_CreateObjective (required)
 * 1: State    <STRING>  - SUCCEEDED / FAILED / CANCELED / ASSIGNED / CREATED (default: "SUCCEEDED")
 *
 * Return Value:
 * Nothing usable. Empty IDs are logged and ignored; a client call only queues server work.
 *
 * Example:
 * ["secure_lz", "SUCCEEDED"] call Waldo_fnc_SetObjectiveState;
 * Result: the task is succeeded, its WMP marker is removed, and the AAR state is updated.
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

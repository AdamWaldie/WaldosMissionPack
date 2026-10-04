/*
 * Author: WaldoTheWarfighter
 * Creates a BIS task from a mission script or trigger and records it in the AAR ledger.
 * Locality and authority: the server creates the task and optional map marker. Client calls forward to the
 * server; BIS task state is JIP-safe and the AAR ledger is public. Reusing a task ID updates its
 * ledger row. A separate WMP marker is made only for an array destination with two coordinates.
 * Current callers: mission-maker scripts/triggers; the full-pack audit checks this public API.
 *
 * Arguments:
 * 0: Task ID       <STRING>                       - non-empty id, used to update the task later
 * 1: Owner         <SIDE/GROUP/OBJECT/ARRAY>      - task recipients (default: west)
 * 2: Title         <STRING>                       - short task title (default: "New Task")
 * 3: Description   <STRING>                       - longer description (default: "")
 * 4: Destination   <ARRAY/OBJECT/STRING>          - BIS task position/object/marker (default: [])
 * 5: State         <STRING>                       - CREATED/ASSIGNED/SUCCEEDED/... (default: "ASSIGNED")
 * 6: Create marker <BOOL>                         - extra marker for array position only (default: true)
 * 7: Task type     <STRING>                       - task icon type (default: "" = default icon)
 *
 * Repeat / JIP: Server calls update the task; client Eden Init replays are ignored.
 * Later client calls forward to the server. BIS task state and the AAR ledger synchronize to JIP.
 * Current callers: mission-maker Eden Init fields, scripts and triggers.
 *
 * Return Value:
 * Nothing usable. Empty task IDs are logged and ignored; a client call only queues server work.
 *
 * Example:
 * ["secure_lz", west, "Secure the LZ", "Clear and hold the landing zone.", getMarkerPos "lz1"] call Waldo_fnc_CreateObjective;
 * Result: west receives the assigned task; the server also places its WMP objective marker.
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
    // Init-field replay on a joining client: the server already ran this Init line, and forwarding
    // it again would recreate state removed since. Later script/action calls still forward.
    if !(missionNamespace getVariable ["Waldo_ClientInitPhaseDone", false]) exitWith {
        diag_log format ["[WMP JIP] Skipped Init-field replay of %1 on client %2.", "Waldo_fnc_CreateObjective", clientOwner];
    };
    _this remoteExec ["Waldo_fnc_CreateObjective", 2];
};

// description array is [description, title, waypoint marker text]
[_owner, _taskId, [_description, _title, _title], _destination, _state, 1, true, _taskType, true] call BIS_fnc_taskCreate;

// Register the task in the AAR objective ledger (broadcast so the ENDEX debrief, which runs
// client-side, can read it). Store the player-facing title as well as the scripting ID: the ID is
// useful to code, but strings such as "ied_trigger_analysis" are poor debrief content.
// Ledger entries are [taskId, title, state].
private _ledger = +(missionNamespace getVariable ["Waldo_AAR_Tasks", []]);
private _at = _ledger findIf {(_x select 0) isEqualTo _taskId};
if (_at < 0) then {
    _ledger pushBack [_taskId, _title, _state];
} else {
    _ledger set [_at, [_taskId, _title, _state]];
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

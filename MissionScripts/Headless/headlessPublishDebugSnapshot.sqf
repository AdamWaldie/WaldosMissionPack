/*
 * Author: WaldoTheWarfighter
 * Publishes the server-only groupOwner result needed by the curator HC ownership overlay. Arma's
 * groupOwner command always returns 0 on clients, so interface machines must never query it
 * directly. While debug is enabled this maintains a small public `[group, owner]` snapshot. No
 * worker or snapshot is retained while HC support or HC debug is disabled.
 *
 * Locality and repeat/JIP behaviour:
 * Server-only and repeat-safe. Each start/stop advances Waldo_Headless_DebugGeneration. A retiring
 * worker may clear state only while it still owns that generation, so a rapid off/on transition
 * cannot let an old worker erase the replacement. The public snapshot is available to JIP curators
 * and is broadcast only when ownership changes.
 * Locality and authority: server-only. The server is the only machine that can read authoritative
 * groupOwner values and publish the resulting JIP snapshot; clients consume but never alter it.
 *
 * Arguments: None.
 * Return Value: Boolean - true when the server worker exists or was started.
 * Current callers: initServer.sqf and Waldo_fnc_HeadlessDebugToggle.
 * Example: [] call Waldo_fnc_HeadlessPublishDebugSnapshot;
 * Result: one one-second snapshot worker exists while debug is active; disabling debug or HC
 * cancels it and clears the public snapshot.
 */
if !(isServer) exitWith {false};
private _generation = (missionNamespace getVariable ["Waldo_Headless_DebugGeneration", 0]) + 1;
missionNamespace setVariable ["Waldo_Headless_DebugGeneration", _generation];

private _enabled = missionNamespace getVariable ["Waldo_Headless_Enable", false];
private _debug = missionNamespace getVariable ["Waldo_Headless_Debug", false];
if (!_enabled || {!_debug}) exitWith {
    missionNamespace setVariable ["Waldo_Headless_DebugSnapshotWorkerActive", false];
    [[]] call Waldo_fnc_HeadlessSetDebugSnapshot;
    false
};

missionNamespace setVariable ["Waldo_Headless_DebugSnapshotWorkerActive", true];
[_generation] spawn {
    params ["_generation"];
    while {
        missionNamespace getVariable ["Waldo_Headless_Enable", false]
        && {missionNamespace getVariable ["Waldo_Headless_Debug", false]}
        && {_generation == missionNamespace getVariable ["Waldo_Headless_DebugGeneration", -1]}
    } do {
        private _snapshot = allGroups apply {[_x, groupOwner _x]};
        [_snapshot] call Waldo_fnc_HeadlessSetDebugSnapshot;
        uiSleep 1;
    };
    if (_generation == missionNamespace getVariable ["Waldo_Headless_DebugGeneration", -1]) then {
        [[]] call Waldo_fnc_HeadlessSetDebugSnapshot;
        missionNamespace setVariable ["Waldo_Headless_DebugSnapshotWorkerActive", false];
    };
};
true

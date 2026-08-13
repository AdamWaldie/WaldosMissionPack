/*
 * Author: WaldoTheWarfighter
 * Publishes the server-only groupOwner result needed by the curator HC ownership overlay. Arma's
 * groupOwner command always returns 0 on clients, so interface machines must never query it
 * directly. While debug is enabled this maintains a small public `[group, owner]` snapshot; when
 * debug is disabled it clears the snapshot but keeps one dormant worker ready for a later toggle.
 *
 * Locality and repeat/JIP behaviour:
 * Server-only and repeat-safe. One bounded-frequency worker is identified by
 * Waldo_Headless_DebugSnapshotWorkerActive. The current public snapshot is available to JIP
 * curators and is broadcast only when ownership changes. Keeping the worker alive avoids the
 * disable/enable race where the retiring worker could clear the newly enabled state.
 *
 * Arguments: None.
 * Return Value: Boolean - true when the server worker exists or was started.
 * Current callers: initServer.sqf and Waldo_fnc_HeadlessDebugToggle.
 * Example: [] call Waldo_fnc_HeadlessPublishDebugSnapshot;
 */
if !(isServer) exitWith {false};
if (missionNamespace getVariable ["Waldo_Headless_DebugSnapshotWorkerActive", false]) exitWith {true};

missionNamespace setVariable ["Waldo_Headless_DebugSnapshotWorkerActive", true];
[] spawn {
    while {missionNamespace getVariable ["Waldo_Headless_Enable", false]} do {
        if (missionNamespace getVariable ["Waldo_Headless_Debug", false]) then {
            private _snapshot = allGroups apply {[_x, groupOwner _x]};
            [_snapshot] call Waldo_fnc_HeadlessSetDebugSnapshot;
        } else {
            [[]] call Waldo_fnc_HeadlessSetDebugSnapshot;
        };
        uiSleep 1;
    };
    [[]] call Waldo_fnc_HeadlessSetDebugSnapshot;
    missionNamespace setVariable ["Waldo_Headless_DebugSnapshotWorkerActive", false];
};
true

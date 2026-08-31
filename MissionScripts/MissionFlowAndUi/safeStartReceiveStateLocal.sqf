/*
 * Author: WaldoTheWarfighter
 * Receives one targeted authoritative SafeStart snapshot and reconciles all local protection and UI.
 * Locality/authority: interface client only; accepts snapshots only from the server.
 * Repeat/JIP behaviour: revision ordered and repeat-safe. Older responses are ignored; a live
 * snapshot actively removes any stale freeze left by early JIP initialization.
 * Arguments: active BOOL, reason STRING, end time NUMBER, revision NUMBER.
 * Return Value: BOOL. Current caller: Waldo_fnc_SafeStartRequestStateServer.
 * Example: server-targeted remote execution only.
 */
params [
    ["_active", false, [true]],
    ["_reason", "STARTUP", [""]],
    ["_endTime", 0, [0]],
    ["_revision", 0, [0]]
];
if (!hasInterface || {remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}}) exitWith {false};
private _appliedRevision = missionNamespace getVariable ["Waldo_SafeStart_AppliedRevision", -1];
if (_revision < _appliedRevision) exitWith {
    diag_log format ["[WMP SAFESTART] ignored stale state snapshot revision=%1 appliedRevision=%2", _revision, _appliedRevision];
    false
};
missionNamespace setVariable ["Waldo_SafeStart_LastReason", _reason];
missionNamespace setVariable ["Waldo_SafeStart_EndTime", _endTime];
missionNamespace setVariable ["Waldo_SafeStart_Revision", _revision];
[_active, "STATE_SYNC", _revision] call Waldo_fnc_SafeStartApply;
diag_log format ["[WMP SAFESTART] applied state snapshot state=%1 revision=%2 timerEnd=%3", _active, _revision, _endTime];
true

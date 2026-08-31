/*
 * Author: WaldoTheWarfighter
 * Returns the current authoritative SafeStart state to one joining interface client. This avoids
 * depending on cross-machine public-variable arrival order during JIP.
 * Locality/authority: server only. A remote requester must own the supplied player object.
 * Repeat/JIP behaviour: read-only and repeat-safe; each request returns one targeted snapshot with
 * the current revision. It creates no persistent remote-execution entry.
 * Arguments: requester OBJECT (default objNull).
 * Return Value: BOOL. Current caller: initPlayerLocal.sqf.
 * Example: [player] remoteExecCall ["Waldo_fnc_SafeStartRequestStateServer", 2];
 */
params [["_requester", objNull, [objNull]]];
if (!isServer || {isNull _requester} || {!isPlayer _requester}) exitWith {false};
if (remoteExecutedOwner > 0 && {owner _requester != remoteExecutedOwner}) exitWith {
    diag_log format ["[WMP SAFESTART] rejected state request remoteOwner=%1 playerOwner=%2", remoteExecutedOwner, owner _requester];
    false
};
private _payload = [
    missionNamespace getVariable ["Waldo_SafeStart_Active", false],
    missionNamespace getVariable ["Waldo_SafeStart_LastReason", "STARTUP"],
    missionNamespace getVariable ["Waldo_SafeStart_EndTime", 0],
    missionNamespace getVariable ["Waldo_SafeStart_Revision", 0]
];
_payload remoteExecCall ["Waldo_fnc_SafeStartReceiveStateLocal", owner _requester];
diag_log format ["[WMP SAFESTART] sent state snapshot owner=%1 state=%2 revision=%3", owner _requester, _payload select 0, _payload select 3];
true

/*
 * Author: WaldoTheWarfighter
 * Removes one group's active or stale rally state without changing its server-owned cooldown.
 *
 * The authority token prevents clients or obsolete expiry tasks from removing a newer rally. The
 * BIS respawn handle is validated and removed before the world object is deleted. Cleanup also runs
 * when the public active flag is already false so interrupted deployments cannot leak a respawn.
 *
 * Arguments:
 * 0: group <GROUP>; 1: reason <STRING>; 2: notification state <STRING>;
 * 3: server authority token <STRING>.
 *
 * Return Value: Boolean - true when cleanup ran; otherwise false.
 *
 * Example:
 * [_group, "Rally packed.", "INFO", _authority] call Waldo_fnc_RallyPointRemoveServer;
 *
 * Current callers: RallyPointRequestServer, expiry watcher and RallyPointRemoveAllServer.
 */
params [
    ["_group", grpNull, [grpNull]],
    ["_reason", "Rally point removed.", [""]],
    ["_state", "INFO", [""]],
    ["_authority", "", [""]]
];
if (!isServer || {isNull _group}) exitWith {false};
private _expectedAuthority = missionNamespace getVariable ["Waldo_Rally_ServerAuthority", ""];
if (_authority isEqualTo "" || {_authority != _expectedAuthority}) exitWith {
    diag_log format ["[WMP RALLY] Rejected unauthorised removal group=%1 remoteOwner=%2", groupId _group, remoteExecutedOwner];
    false
};
private _respawn = _group getVariable ["Waldo_Rally_RespawnHandle", []];
if (_respawn isEqualType [] && {count _respawn == 2}) then {
    private _removed = _respawn call BIS_fnc_removeRespawnPosition;
    if !(_removed) then {diag_log format ["[WMP RALLY] Respawn removal returned false group=%1 handle=%2", groupId _group, _respawn]};
};
private _object = _group getVariable ["Waldo_Rally_Object", objNull];
if (!isNull _object) then {deleteVehicle _object};
_group setVariable ["Waldo_Rally_Active", false, true];
_group setVariable ["Waldo_Rally_Object", objNull, true];
_group setVariable ["Waldo_Rally_ExpiresAt", -1, true];
_group setVariable ["Waldo_Rally_RespawnHandle", []];
_group setVariable ["Waldo_Rally_RespawnPosition", [], true];
_group setVariable ["Waldo_Rally_Token", ""];
if (_reason != "") then {[_reason, _state] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", units _group]};
diag_log format ["[WMP RALLY] Removed group=%1 reason=%2", groupId _group, _reason];
true

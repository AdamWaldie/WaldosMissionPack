/*
 * Author: WaldoTheWarfighter
 * Removes every active or stale server-owned rally during runtime disable or curator cleanup.
 *
 * Remote callers require an assigned curator. Groups with a leaked object or respawn handle are
 * cleaned even when their active flag is already false. The authoritative token is passed to the
 * single-group cleanup function so obsolete client calls cannot remove newer state.
 * Locality and authority: Server-only cleanup; remote callers need an assigned curator.
 * Repeat/JIP: Scans active and stale group state on each call; later joiners see cleared public
 * state, not a replayed removal request.
 *
 * Arguments: None.
 * Return Value: Boolean - true when cleanup was scheduled; otherwise false.
 * Example: [] call Waldo_fnc_RallyPointRemoveAllServer;
 * Current caller: the Rally ZEN runtime control through Waldo_fnc_FeatureRuntimeApply.
 * Result: Every active or stale rally object and respawn handle is scheduled for cleanup.
 */
if (!isServer) exitWith {[] remoteExecCall ["Waldo_fnc_RallyPointRemoveAllServer", 2]; false};
private _authorized = true;
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    _authorized = !isNull _caller && {!isNull (getAssignedCuratorLogic _caller)};
};
if (!_authorized) exitWith {false};
private _authority = missionNamespace getVariable ["Waldo_Rally_ServerAuthority", ""];
if (_authority isEqualTo "") then {
    _authority = format ["%1_%2_%3", serverTime, random 1e12, diag_tickTime];
    missionNamespace setVariable ["Waldo_Rally_ServerAuthority", _authority];
};
{
    private _hasState = _x getVariable ["Waldo_Rally_Active", false]
        || {!isNull (_x getVariable ["Waldo_Rally_Object", objNull])}
        || {count (_x getVariable ["Waldo_Rally_RespawnHandle", []]) == 2};
    if (_hasState) then {
        [_x, "Rally-point service was disabled.", "WARNING", _authority] spawn Waldo_fnc_RallyPointRemoveServer;
    };
} forEach allGroups;
true

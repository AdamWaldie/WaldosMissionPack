/*
 * Author: Waldo
 * Disables future breach processing. ACE detonation handlers cannot be removed, so the bridge becomes a no-op.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_BreachingStop;
 */

if !(isServer) exitWith {[] remoteExecCall ["Waldo_fnc_BreachingStop", 2]};

private _remoteAuthorized = true;
if (remoteExecutedOwner > 0) then {
    private _callerIndex = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_callerIndex >= 0) then {allPlayers select _callerIndex} else {objNull};
    _remoteAuthorized = !isNull _caller && {!isNull (getAssignedCuratorLogic _caller)};
};
if !(_remoteAuthorized) exitWith {};

missionNamespace setVariable ["Waldo_Breaching_Enable", false, true];
missionNamespace setVariable ["Waldo_Breaching_Profiles", createHashMap, true];

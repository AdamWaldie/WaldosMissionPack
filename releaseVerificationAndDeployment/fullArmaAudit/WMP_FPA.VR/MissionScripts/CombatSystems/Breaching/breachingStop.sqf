/*
 * Author: WaldoTheWarfighter
 * Disables future breach processing. ACE detonation handlers cannot be removed, so an already
 * installed bridge becomes a no-op. The server also removes the replaceable runtime-init JIP entry
 * so later joiners do not receive obsolete activation work.
 *
 * Locality/authority: server-authoritative. Remote calls are accepted only from an assigned curator.
 * Repeat/JIP behaviour: repeat-safe; publishes the disabled setting and clears stale runtime replay.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_BreachingStop;
 * Current callers: mission-maker scripts and the full-pack function station.
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
[[["Waldo_Breaching_Enable", false]], false] remoteExecCall ["Waldo_fnc_FeatureRuntimeReceiveState", -2];
[] remoteExecCall ["", "Waldo_Breaching_RuntimeInit"];

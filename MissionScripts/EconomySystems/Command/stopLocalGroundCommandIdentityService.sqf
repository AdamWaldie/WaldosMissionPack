/*
 * Author: WaldoTheWarfighter
 * Stops the local Ground Command identity lifecycle service and invalidates pending retries.
 *
 * Locality/authority: interface client only. Repeat/JIP behaviour: repeat-safe; removes the exact
 * CBA player-unit handler and advances epoch/generation so queued callbacks cannot publish or recur.
 * A later Economy enable starts a fresh service against the current player object.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - true after cleanup; false outside an interface client.
 *
 * Current callers: cleanupUnifiedClientLocal during Economy purge.
 *
 * Example:
 * [] call Waldo_fnc_EcoCommand_stopLocalGroundCommandIdentityService;
 */

if (!hasInterface) exitWith {false};

private _eventId = missionNamespace getVariable ["WaldoEcoCommand_LocalIdentityUnitEH", -1];
if (_eventId >= 0) then {
    ["unit", _eventId] call CBA_fnc_removePlayerEventHandler;
};

missionNamespace setVariable ["WaldoEcoCommand_LocalIdentityUnitEH", nil];
missionNamespace setVariable ["WaldoEcoCommand_LocalIdentityServiceStarted", false];
missionNamespace setVariable [
    "WaldoEcoCommand_LocalIdentityServiceEpoch",
    (missionNamespace getVariable ["WaldoEcoCommand_LocalIdentityServiceEpoch", 0]) + 1
];
missionNamespace setVariable [
    "WaldoEcoCommand_LocalIdentityGeneration",
    (missionNamespace getVariable ["WaldoEcoCommand_LocalIdentityGeneration", 0]) + 1
];

true

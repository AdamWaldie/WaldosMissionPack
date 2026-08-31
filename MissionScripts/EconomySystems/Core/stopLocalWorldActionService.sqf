/*
 * Author: WaldoTheWarfighter
 * Stops client-local Economy world-action reconciliation and invalidates pending repair callbacks.
 *
 * Locality/authority: interface client only. Repeat/JIP behaviour: repeat-safe; disables the
 * permanent public-variable listener through its service-state guard and advances the epoch so an
 * already queued callback cannot reschedule. Arma does not expose removal for public-variable event
 * handlers. A later Economy enable reactivates the listener and performs a full reconciliation.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - true after cleanup; false outside an interface client.
 *
 * Current callers: cleanupUnifiedClientLocal during purge.
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_stopLocalWorldActionService;
 */

if (!hasInterface) exitWith {false};

missionNamespace setVariable ["WaldoEcoCore_LocalWorldActionRefreshPending", false];
missionNamespace setVariable ["WaldoEcoCore_LocalWorldActionServiceStarted", false];
missionNamespace setVariable [
    "WaldoEcoCore_LocalWorldActionServiceEpoch",
    (missionNamespace getVariable ["WaldoEcoCore_LocalWorldActionServiceEpoch", 0]) + 1
];

true

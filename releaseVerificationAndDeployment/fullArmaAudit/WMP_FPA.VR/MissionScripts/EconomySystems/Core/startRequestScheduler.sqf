/*
 * Author: WaldoTheWarfighter
 * Start the Economy server's low-frequency runtime-registry recovery service.
 *
 * Locality / Authority:
 * Server authority only. Economy actions submit directly through
 * Waldo_fnc_EcoCore_submitRequestServer; this service does not transport or inspect requests.
 *
 * Repeat / JIP Behaviour:
 * Repeat-safe through one missionNamespace guard. It starts only while Economy authority is active,
 * stops after purge/disable, and can be started again by the existing subsystem startup adapters.
 * JIP does not create another worker because clients fail the authority guard.
 *
 * Arguments:
 * None.
 *
 * Return Value:
 * Nothing.
 *
 * Current Callers:
 * Existing Resource, Research, Build and Buy startup adapters.
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_startRequestScheduler;
 */

if (!([] call Waldo_fnc_EcoCore_canRunBackgroundAuthority)) exitWith {};
if (missionNamespace getVariable ["WaldoEcoCore_RequestSchedulerStarted", false]) exitWith {};
missionNamespace setVariable ["WaldoEcoCore_RequestSchedulerStarted", true];

[] spawn {
    while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
        call Waldo_fnc_EcoCore_refreshRuntimeRegistries;
        uiSleep 10;
    };

    missionNamespace setVariable ["WaldoEcoCore_RequestSchedulerStarted", false];
};

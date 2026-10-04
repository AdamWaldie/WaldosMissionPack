/*
 * Author: WaldoTheWarfighter
 * Start the shared server scheduler that processes building manage requests.
 *
 * Locality / Authority: Called during Economy server initialization; the shared scheduler
 * checks its own authority and repeat state.
 * Repeat/JIP: Scheduler startup is idempotent; clients do not start their own.
 * Current Callers: EconomySystems/economyInit.sqf.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 * Result: Delegates request polling to EcoCore_startRequestScheduler.
 *
 * Example:
 * [] call Waldo_fnc_EcoBuild_startBuildingManageRequestLoop;
 */

        [] call Waldo_fnc_EcoCore_startRequestScheduler;


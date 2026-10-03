/*
 * Author: WaldoTheWarfighter
 * Start the shared server scheduler that processes construction requests.
 *
 * Locality / Authority: Called during Economy server initialization; the shared scheduler
 * owns the actual authority guard.
 * Repeat/JIP: Scheduler startup is idempotent; clients do not start a loop.
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
 * [] call Waldo_fnc_EcoBuild_startConstructionRequestLoop;
 */

        [] call Waldo_fnc_EcoCore_startRequestScheduler;


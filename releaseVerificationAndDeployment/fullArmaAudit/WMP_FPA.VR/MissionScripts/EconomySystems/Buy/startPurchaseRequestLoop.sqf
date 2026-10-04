/*
 * Author: WaldoTheWarfighter
 * Starts the shared Economy scheduler that accepts Purchasing requests.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoBuy_startPurchaseRequestLoop;
 * Locality/Authority: Economy authority through the shared request scheduler.
 * Repeat/JIP Behaviour: Scheduler startup is repeat-safe; pending requests are not JIP state.
 * Current Callers: Economy initialization.
 * Result: Validated purchase requests can be processed by authority.
 */

        [] call Waldo_fnc_EcoCore_startRequestScheduler;


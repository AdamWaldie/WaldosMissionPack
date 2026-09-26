/*
 * Author: WaldoTheWarfighter
 * Starts the shared Economy scheduler that processes Research requests and progress.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoResearch_startResearchRequestLoop;
 * Locality/Authority: Economy authority only through the shared request scheduler.
 * Repeat/JIP Behaviour: Scheduler startup is repeat-safe; clients/JIP consume published state.
 * Current Callers: Economy initialization.
 * Result: The shared scheduler begins accepting Research work when Economy is active.
 */

        [] call Waldo_fnc_EcoCore_startRequestScheduler;


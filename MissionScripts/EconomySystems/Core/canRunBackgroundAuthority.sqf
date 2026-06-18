/*
 * Author: Waldo
 * Returns true on the machine that should run the background authority loops (income generation,
 * production/upkeep, research progress, request processing). This is the server only, so those
 * loops run exactly once for the mission - never once per connected client (the bug that broke the
 * suite on dedicated multiplayer). Kept distinct from canRunAuthority for readability at the call
 * sites that start long-running loops.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - true only on the server
 *
 * Example:
 * if !([] call Waldo_fnc_EcoCore_canRunBackgroundAuthority) exitWith {};
 */

    isServer

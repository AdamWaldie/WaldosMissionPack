/*
 * Author: Waldo
 * Returns whether the Waldos Economy Systems suite is currently active (initialised and not purged).
 * Mission makers can gate dependent scripts on this, e.g.
 * waitUntil { call Waldo_fnc_EcoCore_isActive }.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - true if the economy suite is running
 *
 * Example:
 * if (call Waldo_fnc_EcoCore_isActive) then { hint "Economy online"; };
 */

    missionNamespace getVariable ["WaldoEcoCore_ModuleActive", false]

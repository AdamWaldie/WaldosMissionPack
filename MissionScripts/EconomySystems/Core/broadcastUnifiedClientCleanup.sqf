/*
 * Author: Waldo
 * Broadcast unified client cleanup.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_broadcastUnifiedClientCleanup;
 */

    if (hasInterface) then {
        [] call Waldo_fnc_EcoCore_cleanupUnifiedClientLocal;
    };

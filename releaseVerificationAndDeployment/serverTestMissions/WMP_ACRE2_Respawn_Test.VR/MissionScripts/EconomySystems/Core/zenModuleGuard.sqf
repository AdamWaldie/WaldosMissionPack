/*
 * Author: WaldoTheWarfighter
 * Zen module guard.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Gate every "Waldos Economy Systems" ZEN custom module runs through. ZEN has no clean way
 * to un-register custom modules mid-mission, so after a Purge the modules remain in the Zeus
 * list; this guard makes them no-op (with a notice) instead of acting on a purged / not-yet-
 * initialised economy. Returns true only when the suite is active.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Active <BOOL> - true if the economy is running and the module may proceed
 *
 * Example:
 * if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
 */

    if ([] call Waldo_fnc_EcoCore_isActive) exitWith { true };

    systemChat "Waldos Economy Systems is not active for this mission (purged or not initialised).";
    diag_log format ["[WMP ECO ZEN] rejected module invocation because economy is inactive curator=%1 clientOwner=%2", name player, clientOwner];
    false

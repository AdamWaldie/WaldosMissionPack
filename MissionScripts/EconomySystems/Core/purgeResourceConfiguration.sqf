/*
 * Author: Waldo
 * Purge resource configuration.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_purgeResourceConfiguration;
 */

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _catalog = [[
        "Resource",
        call Waldo_fnc_EcoResource_getDefaultResourceColor,
        call Waldo_fnc_EcoResource_getDefaultResourceIcon,
        -1
    ]];

    missionNamespace setVariable ["WaldoEcoResource_ResourceCatalog", _catalog, true];
    missionNamespace setVariable ["WaldoEcoResource_ResourceTypes", ["Resource"], true];
    [] call Waldo_fnc_EcoResource_initializeResourceData;

/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - purgeResourceConfiguration
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_purgeResourceConfiguration via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

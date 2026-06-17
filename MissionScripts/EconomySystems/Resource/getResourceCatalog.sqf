/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getResourceCatalog
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getResourceCatalog via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    private _catalog = +(missionNamespace getVariable ["WaldoEcoResource_ResourceCatalog", []]);
    if ((count _catalog) isEqualTo 0) then {
        _catalog = [["Resource", call Waldo_fnc_EcoResource_getDefaultResourceColor, call Waldo_fnc_EcoResource_getDefaultResourceIcon, -1]];
    };
    _catalog

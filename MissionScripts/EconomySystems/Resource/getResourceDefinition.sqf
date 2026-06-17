/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getResourceDefinition
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getResourceDefinition via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_resourceType"];

    private _catalog = call Waldo_fnc_EcoResource_getResourceCatalog;
    private _index = _catalog findIf {
        ((_x param [0, ""]) isEqualTo _resourceType)
    };

    if (_index < 0) exitWith {[]};
    +(_catalog select _index)

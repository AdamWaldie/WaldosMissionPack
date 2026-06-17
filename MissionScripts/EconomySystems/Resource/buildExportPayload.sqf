/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - buildExportPayload
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_buildExportPayload via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_includeValues", false]];

    private _catalog = call Waldo_fnc_EcoResource_getResourceCatalog;
    private _sideData = [];

    if (_includeValues) then {
        _sideData = call Waldo_fnc_EcoResource_getAllSideResourceRows;
    };

    str ["WaldoEcoResource_CONFIG_V3", _catalog, _includeValues, _sideData]

/*
 * Author: Waldo
 * Build export payload.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _includeValues <BOOL> - include values (optional, default: false)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_includeValues] call Waldo_fnc_EcoResource_buildExportPayload;
 */

    params [["_includeValues", false]];

    private _catalog = call Waldo_fnc_EcoResource_getResourceCatalog;
    private _sideData = [];

    if (_includeValues) then {
        _sideData = call Waldo_fnc_EcoResource_getAllSideResourceRows;
    };

    str ["WaldoEcoResource_CONFIG_V3", _catalog, _includeValues, _sideData]

/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - initializeResourceData
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_initializeResourceData via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _legacyTypes = missionNamespace getVariable ["WaldoEcoResource_ResourceTypes", ["Resource"]];
    if !(_legacyTypes isEqualType []) then {
        _legacyTypes = ["Resource"];
    };

    private _catalog = missionNamespace getVariable ["WaldoEcoResource_ResourceCatalog", []];
    if !(_catalog isEqualType []) then {
        _catalog = [];
    };

    if ((count _catalog) isEqualTo 0) then {
        _catalog = _legacyTypes apply {[_x, call Waldo_fnc_EcoResource_getDefaultResourceColor, call Waldo_fnc_EcoResource_getDefaultResourceIcon, -1]};
    };

    _catalog = [_catalog] call Waldo_fnc_EcoResource_normalizeResourceCatalog;
    private _types = _catalog apply {_x param [0, "Resource"]};

    missionNamespace setVariable ["WaldoEcoResource_ResourceCatalog", _catalog, true];
    missionNamespace setVariable ["WaldoEcoResource_ResourceTypes", _types, true];

    {
        private _varName = _x;
        private _existing = missionNamespace getVariable [_varName, 0];
        private _rows = [];

        if (_existing isEqualType []) then {
            _rows = +_existing;
        } else {
            _rows = [[_types select 0, 0 max (floor _existing)]];
        };

        _rows = [_rows, _types] call Waldo_fnc_EcoResource_normalizeSideResourceRows;
        missionNamespace setVariable [_varName, _rows, true];
    } forEach [
        "WaldoEcoResource_Resources_WEST",
        "WaldoEcoResource_Resources_EAST",
        "WaldoEcoResource_Resources_GUER",
        "WaldoEcoResource_Resources_CIV"
    ];

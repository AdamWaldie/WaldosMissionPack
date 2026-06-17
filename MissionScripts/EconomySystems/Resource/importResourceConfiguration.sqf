/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - importResourceConfiguration
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_importResourceConfiguration via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_payload", ["_callerName", "Zeus"]];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
    if !([_payload] call Waldo_fnc_EcoResource_validateImportPayload) exitWith {};

    private _version = _payload param [0, ""];
    private _catalog = [];

    if (_version in ["WaldoEcoResource_CONFIG_V2", "WaldoEcoResource_CONFIG_V3"]) then {
        _catalog = [_payload param [1, []]] call Waldo_fnc_EcoResource_normalizeResourceCatalog;
    } else {
        private _types = (_payload param [1, []]) apply {[_x] call Waldo_fnc_EcoResource_normalizeResourceName};
        _types = _types select {_x isNotEqualTo ""};
        _catalog = [_types apply {[_x, call Waldo_fnc_EcoResource_getDefaultResourceColor, call Waldo_fnc_EcoResource_getDefaultResourceIcon, -1]}] call Waldo_fnc_EcoResource_normalizeResourceCatalog;
    };

    private _types = _catalog apply {_x param [0, "Resource"]};
    if ((count _types) <= 0) exitWith {};

    private _includeValues = _payload param [2, false];
    private _sideData = _payload param [3, []];

    missionNamespace setVariable ["WaldoEcoResource_ResourceCatalog", _catalog, true];
    missionNamespace setVariable ["WaldoEcoResource_ResourceTypes", _types, true];

    if (_includeValues) then {
        {
            private _sideKey = toUpper (_x param [0, ""]);
            private _rows = _x param [1, []];
            private _varName = [_sideKey] call Waldo_fnc_EcoResource_getSideStorageVar;

            if (_varName isNotEqualTo "") then {
                missionNamespace setVariable [_varName, [_rows, _types] call Waldo_fnc_EcoResource_normalizeSideResourceRows, true];
            };
        } forEach _sideData;
    };

    [] call Waldo_fnc_EcoResource_initializeResourceData;

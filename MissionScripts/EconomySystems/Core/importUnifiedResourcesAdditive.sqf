/*
 * Author: Waldo
 * Import unified resources additive.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _payload <ARRAY> - payload (optional, default: [])
 * 1: _callerName <STRING> - caller name (optional, default: "Zeus")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_payload, _callerName] call Waldo_fnc_EcoCore_importUnifiedResourcesAdditive;
 */

    params [
        ["_payload", []],
        ["_callerName", "Zeus"]
    ];

    if (isNil "Waldo_fnc_EcoCore_canRunAuthority" || {!([] call Waldo_fnc_EcoCore_canRunAuthority)}) exitWith {false};
    if (isNil "Waldo_fnc_EcoResource_validateImportPayload" || {isNil "Waldo_fnc_EcoResource_getResourceCatalog"} || {isNil "Waldo_fnc_EcoResource_normalizeResourceCatalog"}) exitWith {false};
    if !([_payload] call Waldo_fnc_EcoResource_validateImportPayload) exitWith {false};

    private _version = _payload param [0, ""];
    private _incomingCatalog = [];

    if (_version in ["WaldoEcoResource_CONFIG_V2", "WaldoEcoResource_CONFIG_V3"]) then {
        _incomingCatalog = [_payload param [1, []]] call Waldo_fnc_EcoResource_normalizeResourceCatalog;
    } else {
        private _types = (_payload param [1, []]) apply {[_x] call Waldo_fnc_EcoResource_normalizeResourceName};
        _types = _types select {_x isNotEqualTo ""};
        _incomingCatalog = [_types apply {[_x, call Waldo_fnc_EcoResource_getDefaultResourceColor, call Waldo_fnc_EcoResource_getDefaultResourceIcon, -1]}] call Waldo_fnc_EcoResource_normalizeResourceCatalog;
    };

    private _mergedCatalog = [call Waldo_fnc_EcoResource_getResourceCatalog, _incomingCatalog] call Waldo_fnc_EcoCore_mergeNamedEntryCatalogs;
    _mergedCatalog = [_mergedCatalog] call Waldo_fnc_EcoResource_normalizeResourceCatalog;
    private _types = _mergedCatalog apply {_x param [0, "Resource"]};

    missionNamespace setVariable ["WaldoEcoResource_ResourceCatalog", _mergedCatalog, true];
    missionNamespace setVariable ["WaldoEcoResource_ResourceTypes", _types, true];

    if ((_payload param [2, false])) then {
        {
            private _sideKey = toUpper (_x param [0, ""]);
            private _rows = _x param [1, []];
            private _varName = [_sideKey] call Waldo_fnc_EcoResource_getSideStorageVar;
            if (_varName isEqualTo "") then {continue;};

            private _existingRows = +(missionNamespace getVariable [_varName, []]);
            _existingRows = [_existingRows, _types] call Waldo_fnc_EcoResource_normalizeSideResourceRows;
            private _incomingRows = [_rows, _types] call Waldo_fnc_EcoResource_normalizeSideResourceRows;
            private _mergedRows = [ +_existingRows, +_incomingRows ] call Waldo_fnc_EcoCore_mergeNamedEntryCatalogs;
            missionNamespace setVariable [_varName, [_mergedRows, _types] call Waldo_fnc_EcoResource_normalizeSideResourceRows, true];
        } forEach (_payload param [3, []]);
    };

    [] call Waldo_fnc_EcoResource_initializeResourceData;
    true

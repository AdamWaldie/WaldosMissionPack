/*
 * Author: Waldo
 * Remove resource type.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _resourceType <ANY> - resource type
 * 1: _callerName <STRING> - caller name (optional, default: "Zeus")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_resourceType, _callerName] call Waldo_fnc_EcoResource_removeResourceType;
 */

    params ["_resourceType", ["_callerName", "Zeus"]];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _safeType = [_resourceType] call Waldo_fnc_EcoResource_normalizeResourceName;
    if (_safeType isEqualTo "") exitWith {};

    private _types = call Waldo_fnc_EcoResource_getResourceTypes;
    if ((count _types) <= 1) exitWith {};

    private _removeIndex = _types findIf {
        (toLower _x) isEqualTo (toLower _safeType)
    };

    if (_removeIndex < 0) exitWith {};

    private _catalog = call Waldo_fnc_EcoResource_getResourceCatalog;
    private _catalogIndex = _catalog findIf {
        (toLower (_x param [0, ""])) isEqualTo (toLower _safeType)
    };

    _types deleteAt _removeIndex;
    if (_catalogIndex >= 0) then {
        _catalog deleteAt _catalogIndex;
    };

    missionNamespace setVariable ["WaldoEcoResource_ResourceCatalog", [_catalog] call Waldo_fnc_EcoResource_normalizeResourceCatalog, true];
    missionNamespace setVariable ["WaldoEcoResource_ResourceTypes", _types, true];
    [] call Waldo_fnc_EcoResource_initializeResourceData;

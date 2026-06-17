/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - removeResourceType
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_removeResourceType via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

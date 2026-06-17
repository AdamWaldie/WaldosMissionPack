/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - addResourceType
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_addResourceType via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_resourceType", ["_color", "#FFFFFF"], ["_icon", ""], ["_baseStorage", -1], ["_callerName", "Zeus"]];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _safeType = [_resourceType] call Waldo_fnc_EcoResource_normalizeResourceName;
    if (_safeType isEqualTo "") exitWith {};

    if ((_baseStorage isEqualType "") && {_callerName isEqualTo "Zeus"}) then {
        _callerName = _baseStorage;
        _baseStorage = -1;
    };
    _baseStorage = [_baseStorage] call Waldo_fnc_EcoResource_normalizeResourceBaseStorage;

    private _types = call Waldo_fnc_EcoResource_getResourceTypes;
    private _existingIndex = _types findIf {
        (toLower _x) isEqualTo (toLower _safeType)
    };

    private _catalog = call Waldo_fnc_EcoResource_getResourceCatalog;
    private _entry = [
        _safeType,
        [_color] call Waldo_fnc_EcoResource_normalizeResourceColor,
        _icon,
        _baseStorage
    ];

    if (_existingIndex >= 0) then {
        _catalog set [_existingIndex, _entry];
    } else {
        _catalog pushBack _entry;
    };

    _catalog = [_catalog] call Waldo_fnc_EcoResource_normalizeResourceCatalog;
    _types = _catalog apply {_x param [0, "Resource"]};

    missionNamespace setVariable ["WaldoEcoResource_ResourceCatalog", _catalog, true];
    missionNamespace setVariable ["WaldoEcoResource_ResourceTypes", _types, true];
    [] call Waldo_fnc_EcoResource_initializeResourceData;

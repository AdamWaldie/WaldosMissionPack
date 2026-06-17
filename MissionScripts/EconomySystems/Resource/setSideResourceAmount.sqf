/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - setSideResourceAmount
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_setSideResourceAmount via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_sideKey", "_resourceType", ["_value", 0], ["_callerName", "Zeus"]];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _safeType = [_resourceType] call Waldo_fnc_EcoResource_normalizeResourceName;
    if (_safeType isEqualTo "") exitWith {};

    private _varName = [_sideKey] call Waldo_fnc_EcoResource_getSideStorageVar;
    if (_varName isEqualTo "") exitWith {};

    private _types = call Waldo_fnc_EcoResource_getResourceTypes;
    if ((_types find _safeType) < 0) exitWith {};

    private _rows = +(missionNamespace getVariable [_varName, []]);
    _rows = [_rows, _types] call Waldo_fnc_EcoResource_normalizeSideResourceRows;

    private _safeValue = 0 max (floor _value);
    private _index = _rows findIf {
        ((_x param [0, ""]) isEqualTo _safeType)
    };

    if (_index < 0) then {
        _rows pushBack [_safeType, _safeValue];
    } else {
        _rows set [_index, [_safeType, _safeValue]];
    };

    missionNamespace setVariable [_varName, _rows, true];

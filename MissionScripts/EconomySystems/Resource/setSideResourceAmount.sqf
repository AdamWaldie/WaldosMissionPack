/*
 * Author: Waldo
 * Set side resource amount.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _resourceType <ANY> - resource type
 * 2: _value <SCALAR> - value (optional, default: 0)
 * 3: _callerName <STRING> - caller name (optional, default: "Zeus")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_sideKey, _resourceType, _value, _callerName] call Waldo_fnc_EcoResource_setSideResourceAmount;
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

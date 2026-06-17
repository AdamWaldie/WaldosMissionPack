/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - normalizeResourceColor
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_normalizeResourceColor via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_color", ""]];

    private _safeColor = if (_color isEqualType "") then {toUpper _color} else {""};
    if (_safeColor isEqualTo "") exitWith {call Waldo_fnc_EcoResource_getDefaultResourceColor};
    if ((_safeColor select [0, 1]) isNotEqualTo "#") then {
        _safeColor = "#" + _safeColor;
    };
    if ((count _safeColor) isNotEqualTo 7) exitWith {call Waldo_fnc_EcoResource_getDefaultResourceColor};
    _safeColor

/*
 * Author: Waldo
 * Normalize resource color.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _color <STRING> - color (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_color] call Waldo_fnc_EcoResource_normalizeResourceColor;
 */

    params [["_color", ""]];

    private _safeColor = if (_color isEqualType "") then {toUpper _color} else {""};
    if (_safeColor isEqualTo "") exitWith {call Waldo_fnc_EcoResource_getDefaultResourceColor};
    if ((_safeColor select [0, 1]) isNotEqualTo "#") then {
        _safeColor = "#" + _safeColor;
    };
    if ((count _safeColor) isNotEqualTo 7) exitWith {call Waldo_fnc_EcoResource_getDefaultResourceColor};
    _safeColor

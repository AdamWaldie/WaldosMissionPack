/*
 * Author: Waldo
 * Normalize resource base storage.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _value <SCALAR> - value (optional, default: -1)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_value] call Waldo_fnc_EcoResource_normalizeResourceBaseStorage;
 */

    params [["_value", -1]];

    private _safe = _value;
    if (_safe isEqualType "") then {
        private _trimmed = [_safe] call Waldo_fnc_EcoResource_normalizeResourceName;
        if (_trimmed isEqualTo "") exitWith {-1};
        _safe = floor (parseNumber _trimmed);
    };

    if !(_safe isEqualType 0) then {
        _safe = floor (parseNumber str _safe);
    };

    if (_safe <= 0) exitWith {-1};
    floor _safe

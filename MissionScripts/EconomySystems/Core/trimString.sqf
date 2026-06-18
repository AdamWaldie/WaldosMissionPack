/*
 * Author: Waldo
 * Trim string.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _value <STRING> - value (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_value] call Waldo_fnc_EcoCore_trimString;
 */

    params [["_value", ""]];

    private _text = if (_value isEqualType "") then {_value} else {str _value};
    private _chars = toArray _text;
    private _start = 0;
    private _end = (count _chars) - 1;

    while {_start <= _end && {(_chars select _start) in [9, 10, 13, 32]}} do {
        _start = _start + 1;
    };

    while {_end >= _start && {(_chars select _end) in [9, 10, 13, 32]}} do {
        _end = _end - 1;
    };

    if (_end < _start) exitWith {""};
    toString (_chars select [_start, (_end - _start) + 1])

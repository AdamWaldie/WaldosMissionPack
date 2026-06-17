/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - trimString
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_trimString via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

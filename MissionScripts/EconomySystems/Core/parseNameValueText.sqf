/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - parseNameValueText
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_parseNameValueText via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_text", ""]];

    private _result = [];
    private _lines = _text splitString toString [10];

    {
        private _line = [_x] call Waldo_fnc_EcoCore_trimString;
        if (_line isEqualTo "") then {continue;};

        private _chars = toArray _line;
        private _sepIndex = _chars findIf {_x in [58, 61]};
        if (_sepIndex < 0) then {continue;};

        private _name = [_line select [0, _sepIndex]] call Waldo_fnc_EcoCore_trimString;
        private _valueText = [_line select [_sepIndex + 1]] call Waldo_fnc_EcoCore_trimString;
        private _value = floor (parseNumber _valueText);

        if (_name isEqualTo "") then {continue;};
        if (_value <= 0) then {continue;};
        _result pushBack [_name, _value];
    } forEach _lines;

    [_result] call Waldo_fnc_EcoCore_normalizeNameValueRows

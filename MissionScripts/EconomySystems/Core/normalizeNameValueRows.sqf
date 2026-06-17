/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - normalizeNameValueRows
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_normalizeNameValueRows via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_rows", []]];

    private _result = [];

    {
        private _name = [(_x param [0, ""])] call Waldo_fnc_EcoCore_trimString;
        private _value = floor (_x param [1, 0]);
        if (_name isEqualTo "") then {continue;};
        if (_value <= 0) then {continue;};

        private _existing = _result findIf {((_x param [0, ""]) isEqualTo _name)};
        if (_existing < 0) then {
            _result pushBack [_name, _value];
        } else {
            _result set [_existing, [_name, _value]];
        };
    } forEach _rows;

    _result

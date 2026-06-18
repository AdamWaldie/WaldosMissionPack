/*
 * Author: Waldo
 * Normalize name value rows.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _rows <ARRAY> - rows (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_rows] call Waldo_fnc_EcoCore_normalizeNameValueRows;
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

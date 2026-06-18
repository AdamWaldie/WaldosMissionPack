/*
 * Author: Waldo
 * Normalize name list.
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
 * [_rows] call Waldo_fnc_EcoCore_normalizeNameList;
 */

    params [["_rows", []]];

    private _result = [];

    {
        private _name = [_x] call Waldo_fnc_EcoCore_trimString;
        if (_name isEqualTo "") then {continue;};
        if ((_result findIf {(toLower _x) isEqualTo (toLower _name)}) >= 0) then {continue;};
        _result pushBack _name;
    } forEach _rows;

    _result

/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - normalizeNameList
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_normalizeNameList via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

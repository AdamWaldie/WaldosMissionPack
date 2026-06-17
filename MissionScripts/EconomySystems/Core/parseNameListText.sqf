/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - parseNameListText
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_parseNameListText via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_text", ""]];

    private _rows = [];
    {
        private _line = [_x] call Waldo_fnc_EcoCore_trimString;
        if (_line isEqualTo "") then {continue;};
        _rows pushBack _line;
    } forEach (_text splitString toString [10]);

    [_rows] call Waldo_fnc_EcoCore_normalizeNameList

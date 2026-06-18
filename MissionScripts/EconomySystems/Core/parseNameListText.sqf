/*
 * Author: Waldo
 * Parse name list text.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _text <STRING> - text (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_text] call Waldo_fnc_EcoCore_parseNameListText;
 */

    params [["_text", ""]];

    private _rows = [];
    {
        private _line = [_x] call Waldo_fnc_EcoCore_trimString;
        if (_line isEqualTo "") then {continue;};
        _rows pushBack _line;
    } forEach (_text splitString toString [10]);

    [_rows] call Waldo_fnc_EcoCore_normalizeNameList

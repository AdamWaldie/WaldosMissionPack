/*
 * Author: Waldo
 * Format name value text.
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
 * [_rows] call Waldo_fnc_EcoCore_formatNameValueText;
 */

    params [["_rows", []]];

    private _safeRows = _rows;
    if !(_safeRows isEqualType []) exitWith {""};
    if ((count _safeRows) > 0 && {!((_safeRows select 0) isEqualType [])}) then {
        _safeRows = [_safeRows];
    };

    (_safeRows apply {format ["%1=%2", _x param [0, ""], _x param [1, 0]]}) joinString toString [10]

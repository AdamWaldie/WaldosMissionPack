/*
 * Author: Waldo
 * Format name list text.
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
 * [_rows] call Waldo_fnc_EcoCore_formatNameListText;
 */

    params [["_rows", []]];
    if !(_rows isEqualType []) exitWith {""};
    _rows joinString toString [10]

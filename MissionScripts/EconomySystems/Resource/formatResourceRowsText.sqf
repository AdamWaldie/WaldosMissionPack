/*
 * Author: Waldo
 * Format resource rows text.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _rows <ARRAY> - rows (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_rows] call Waldo_fnc_EcoResource_formatResourceRowsText;
 */

    params [["_rows", []]];
    (_rows apply {format ["%1=%2", _x param [0, ""], _x param [1, 0]]}) joinString toString [10]

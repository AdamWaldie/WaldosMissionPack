/*
 * Author: Waldo
 * Get resource rows summary text.
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
 * [_rows] call Waldo_fnc_EcoResource_getResourceRowsSummaryText;
 */

    params [["_rows", []]];
    if ((count _rows) <= 0) exitWith {"No resources"};
    (_rows apply {format ["%1 x%2", _x param [0, ""], _x param [1, 0]]}) joinString ", "

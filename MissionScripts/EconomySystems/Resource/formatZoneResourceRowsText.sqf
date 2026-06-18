/*
 * Author: Waldo
 * Format zone resource rows text.
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
 * [_rows] call Waldo_fnc_EcoResource_formatZoneResourceRowsText;
 */

    params [["_rows", []]];

    (([_rows] call Waldo_fnc_EcoResource_normalizeZoneResourceRows) apply {
        private _name = _x param [0, ""];
        private _amount = _x param [1, 0];
        private _total = _x param [3, -1];
        if (_total > 0) then {
            format ["%1=%2/%3", _name, _amount, _total]
        } else {
            format ["%1=%2", _name, _amount]
        }
    }) joinString toString [10]

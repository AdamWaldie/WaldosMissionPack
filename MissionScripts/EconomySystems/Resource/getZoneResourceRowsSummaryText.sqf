/*
 * Author: Waldo
 * Get zone resource rows summary text.
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
 * [_rows] call Waldo_fnc_EcoResource_getZoneResourceRowsSummaryText;
 */

    params [["_rows", []]];

    private _safeRows = [_rows] call Waldo_fnc_EcoResource_normalizeZoneResourceRows;
    if ((count _safeRows) <= 0) exitWith {"No resources"};

    (_safeRows apply {
        private _name = _x param [0, ""];
        private _amount = _x param [1, 0];
        private _remaining = _x param [2, -1];
        private _total = _x param [3, -1];
        if (_total > 0) then {
            format ["%1 x%2 (%3/%4 left)", _name, _amount, 0 max _remaining, _total]
        } else {
            format ["%1 x%2 (infinite)", _name, _amount]
        }
    }) joinString ", "

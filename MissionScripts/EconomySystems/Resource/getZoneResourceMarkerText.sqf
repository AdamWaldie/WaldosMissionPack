/*
 * Author: Waldo
 * Get zone resource marker text.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _row <ARRAY> - row (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_row] call Waldo_fnc_EcoResource_getZoneResourceMarkerText;
 */

    params [["_row", []]];

    private _name = _row param [0, "Resource"];
    private _remaining = _row param [2, -1];
    private _total = _row param [3, -1];

    if (_total > 0) exitWith {
        format ["%1 (%2/%3)", _name, 0 max _remaining, _total]
    };

    format ["%1 (infinite)", _name]

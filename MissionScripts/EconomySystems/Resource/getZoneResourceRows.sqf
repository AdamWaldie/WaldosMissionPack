/*
 * Author: Waldo
 * Get zone resource rows.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _zone <ARRAY> - zone (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_zone] call Waldo_fnc_EcoResource_getZoneResourceRows;
 */

    params [["_zone", []]];

    private _rows = _zone param [4, []];
    if (_rows isEqualType [] && {(count _rows) > 0} && {((_rows select 0) isEqualType [])}) exitWith {
        [_rows] call Waldo_fnc_EcoResource_normalizeZoneResourceRows
    };

    private _legacyType = _zone param [4, ""];
    private _legacyAmount = _zone param [6, 0];
    if !(_legacyType isEqualType "") exitWith {[]};
    if (_legacyType isEqualTo "" || {_legacyAmount <= 0}) exitWith {[]};
    [[_legacyType, _legacyAmount, -1, -1]] call Waldo_fnc_EcoResource_normalizeZoneResourceRows

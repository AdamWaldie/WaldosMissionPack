/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getZoneResourceRows
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getZoneResourceRows via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

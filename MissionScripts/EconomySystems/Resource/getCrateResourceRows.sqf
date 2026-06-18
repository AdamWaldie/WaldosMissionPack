/*
 * Author: Waldo
 * Get crate resource rows.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _crate <OBJECT> - crate (optional, default: objNull)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_crate] call Waldo_fnc_EcoResource_getCrateResourceRows;
 */

    params [["_crate", objNull]];

    if (isNull _crate) exitWith {[]};

    private _rows = _crate getVariable ["WaldoEcoResource_ResourceRows", []];
    if (_rows isEqualType [] && {(count _rows) > 0}) exitWith {[_rows] call Waldo_fnc_EcoResource_normalizeResourceRows};

    private _legacyType = _crate getVariable ["WaldoEcoResource_ResourceType", ""];
    private _legacyValue = _crate getVariable ["WaldoEcoResource_ResourceValue", 0];
    if (_legacyType isEqualTo "" || {_legacyValue <= 0}) exitWith {[]};
    [[_legacyType, _legacyValue]] call Waldo_fnc_EcoResource_normalizeResourceRows

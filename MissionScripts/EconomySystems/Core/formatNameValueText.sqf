/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - formatNameValueText
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_formatNameValueText via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_rows", []]];

    private _safeRows = _rows;
    if !(_safeRows isEqualType []) exitWith {""};
    if ((count _safeRows) > 0 && {!((_safeRows select 0) isEqualType [])}) then {
        _safeRows = [_safeRows];
    };

    (_safeRows apply {format ["%1=%2", _x param [0, ""], _x param [1, 0]]}) joinString toString [10]

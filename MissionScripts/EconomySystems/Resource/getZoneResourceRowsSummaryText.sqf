/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getZoneResourceRowsSummaryText
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getZoneResourceRowsSummaryText via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

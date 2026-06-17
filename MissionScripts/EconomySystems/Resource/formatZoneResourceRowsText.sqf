/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - formatZoneResourceRowsText
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_formatZoneResourceRowsText via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getZoneResourceMarkerText
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getZoneResourceMarkerText via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_row", []]];

    private _name = _row param [0, "Resource"];
    private _remaining = _row param [2, -1];
    private _total = _row param [3, -1];

    if (_total > 0) exitWith {
        format ["%1 (%2/%3)", _name, 0 max _remaining, _total]
    };

    format ["%1 (infinite)", _name]

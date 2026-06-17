/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getZoneAtPos
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getZoneAtPos via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_pos"];

    private _zones = call Waldo_fnc_EcoResource_getResourceZones;
    private _index = _zones findIf {
        private _zonePos = _x param [2, [0, 0, 0]];
        private _zoneRadius = _x param [3, 0];
        ((_pos distance2D _zonePos) <= _zoneRadius)
    };

    if (_index < 0) exitWith {[]};
    +(_zones select _index)

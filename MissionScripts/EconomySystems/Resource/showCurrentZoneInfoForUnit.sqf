/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - showCurrentZoneInfoForUnit
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_showCurrentZoneInfoForUnit via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_unit", objNull]];

    if !([_unit] call Waldo_fnc_EcoResource_canUnitViewCurrentZone) exitWith {};
    private _zone = [_unit] call Waldo_fnc_EcoResource_getCurrentZoneForUnit;
    private _zoneId = _zone param [0, ""];
    if (_zoneId isEqualTo "") exitWith {};

    [_zoneId] call Waldo_fnc_EcoResource_showZoneInfo;

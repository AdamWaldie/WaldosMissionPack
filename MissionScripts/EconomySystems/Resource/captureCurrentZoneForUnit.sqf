/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - captureCurrentZoneForUnit
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_captureCurrentZoneForUnit via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_unit", objNull]];

    if !([_unit] call Waldo_fnc_EcoResource_canUnitCaptureCurrentZone) exitWith {};
    private _zone = [_unit] call Waldo_fnc_EcoResource_getCurrentZoneForUnit;
    private _zoneId = _zone param [0, ""];
    if (_zoneId isEqualTo "") exitWith {};

    [_zoneId, _unit] call Waldo_fnc_EcoResource_captureResourceZone;

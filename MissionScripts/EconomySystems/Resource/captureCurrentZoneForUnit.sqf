/*
 * Author: Waldo
 * Capture current zone for unit.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _unit <OBJECT> - unit (optional, default: objNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_unit] call Waldo_fnc_EcoResource_captureCurrentZoneForUnit;
 */

    params [["_unit", objNull]];

    if !([_unit] call Waldo_fnc_EcoResource_canUnitCaptureCurrentZone) exitWith {};
    private _zone = [_unit] call Waldo_fnc_EcoResource_getCurrentZoneForUnit;
    private _zoneId = _zone param [0, ""];
    if (_zoneId isEqualTo "") exitWith {};

    [_zoneId, _unit] call Waldo_fnc_EcoResource_captureResourceZone;

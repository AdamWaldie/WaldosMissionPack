/*
 * Author: Waldo
 * Capture resource zone.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _zoneId <ANY> - zone id
 * 1: _caller <ANY> - caller
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_zoneId, _caller] call Waldo_fnc_EcoResource_captureResourceZone;
 */

    params ["_zoneId", "_caller"];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
    if (isNull _caller) exitWith {};

    private _sideKey = [side group _caller] call Waldo_fnc_EcoResource_getSideKeyFromSide;
    [_zoneId, _sideKey, getPosATL _caller, name _caller] call Waldo_fnc_EcoResource_captureResourceZoneForSideKey;

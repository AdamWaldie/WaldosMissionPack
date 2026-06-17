/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - captureResourceZone
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_captureResourceZone via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_zoneId", "_caller"];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
    if (isNull _caller) exitWith {};

    private _sideKey = [side group _caller] call Waldo_fnc_EcoResource_getSideKeyFromSide;
    [_zoneId, _sideKey, getPosATL _caller, name _caller] call Waldo_fnc_EcoResource_captureResourceZoneForSideKey;

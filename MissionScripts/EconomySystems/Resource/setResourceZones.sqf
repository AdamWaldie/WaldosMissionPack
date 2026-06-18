/*
 * Author: Waldo
 * Set resource zones.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _zones <ANY> - zones
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_zones] call Waldo_fnc_EcoResource_setResourceZones;
 */

    params ["_zones"];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
    missionNamespace setVariable ["WaldoEcoResource_ResourceZones", _zones, true];

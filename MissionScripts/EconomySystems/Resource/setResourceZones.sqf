/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - setResourceZones
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_setResourceZones via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_zones"];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
    missionNamespace setVariable ["WaldoEcoResource_ResourceZones", _zones, true];

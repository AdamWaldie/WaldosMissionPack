/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - cycleResourceZoneOwner
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_cycleResourceZoneOwner via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_disp", ["_delta", 0]];

    if (isNull _disp) exitWith {};
    _disp setVariable ["WaldoEcoResource_ZoneOwnerIndex", (_disp getVariable ["WaldoEcoResource_ZoneOwnerIndex", 0]) + _delta];
    [_disp] call Waldo_fnc_EcoResource_refreshResourceZonePrompt;

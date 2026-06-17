/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - cycleResourceConfigIcon
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_cycleResourceConfigIcon via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_disp", ["_delta", 0]];
    [_disp, _delta, "WaldoEcoResource_ConfigIconIndex", "WaldoEcoResource_ConfigIconValue"] call Waldo_fnc_EcoCore_cycleMarkerIconSelector;

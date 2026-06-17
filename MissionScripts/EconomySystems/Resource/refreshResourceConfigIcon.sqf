/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - refreshResourceConfigIcon
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_refreshResourceConfigIcon via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_disp"];
    [_disp, "WaldoEcoResource_ConfigIconIndex", "WaldoEcoResource_ConfigIconValue"] call Waldo_fnc_EcoCore_refreshMarkerIconSelector;

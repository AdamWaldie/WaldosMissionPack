/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - cycleBuildConfigIcon
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_cycleBuildConfigIcon via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_disp", ["_delta", 0]];
        [_disp, _delta, "WaldoEcoBuild_ConfigIconIndex", "WaldoEcoBuild_ConfigIconValue"] call Waldo_fnc_EcoCore_cycleMarkerIconSelector;


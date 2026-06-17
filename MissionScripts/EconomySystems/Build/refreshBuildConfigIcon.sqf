/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - refreshBuildConfigIcon
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_refreshBuildConfigIcon via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_disp"];
        [_disp, "WaldoEcoBuild_ConfigIconIndex", "WaldoEcoBuild_ConfigIconValue"] call Waldo_fnc_EcoCore_refreshMarkerIconSelector;


/*
 * Author: Waldo
 * Refresh build config icon.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoBuild_refreshBuildConfigIcon;
 */

        params ["_disp"];
        [_disp, "WaldoEcoBuild_ConfigIconIndex", "WaldoEcoBuild_ConfigIconValue"] call Waldo_fnc_EcoCore_refreshMarkerIconSelector;


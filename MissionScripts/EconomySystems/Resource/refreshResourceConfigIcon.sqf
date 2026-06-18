/*
 * Author: Waldo
 * Refresh resource config icon.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoResource_refreshResourceConfigIcon;
 */

    params ["_disp"];
    [_disp, "WaldoEcoResource_ConfigIconIndex", "WaldoEcoResource_ConfigIconValue"] call Waldo_fnc_EcoCore_refreshMarkerIconSelector;

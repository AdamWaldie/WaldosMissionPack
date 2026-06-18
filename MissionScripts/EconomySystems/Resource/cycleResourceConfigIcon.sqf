/*
 * Author: Waldo
 * Cycle resource config icon.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp
 * 1: _delta <SCALAR> - delta (optional, default: 0)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _delta] call Waldo_fnc_EcoResource_cycleResourceConfigIcon;
 */

    params ["_disp", ["_delta", 0]];
    [_disp, _delta, "WaldoEcoResource_ConfigIconIndex", "WaldoEcoResource_ConfigIconValue"] call Waldo_fnc_EcoCore_cycleMarkerIconSelector;

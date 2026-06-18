/*
 * Author: Waldo
 * Cycle purchase config icon.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 * 1: _delta <SCALAR> - delta (optional, default: 0)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _delta] call Waldo_fnc_EcoBuy_cyclePurchaseConfigIcon;
 */

        params [["_disp", displayNull], ["_delta", 0]];
        [_disp, _delta, "WaldoEcoBuy_ConfigIconIndex", "WaldoEcoBuy_ConfigIconValue"] call Waldo_fnc_EcoCore_cycleMarkerIconSelector;


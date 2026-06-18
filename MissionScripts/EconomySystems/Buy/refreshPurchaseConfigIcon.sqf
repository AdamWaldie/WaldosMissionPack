/*
 * Author: Waldo
 * Refresh purchase config icon.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoBuy_refreshPurchaseConfigIcon;
 */

        params [["_disp", displayNull]];
        [_disp, "WaldoEcoBuy_ConfigIconIndex", "WaldoEcoBuy_ConfigIconValue"] call Waldo_fnc_EcoCore_refreshMarkerIconSelector;


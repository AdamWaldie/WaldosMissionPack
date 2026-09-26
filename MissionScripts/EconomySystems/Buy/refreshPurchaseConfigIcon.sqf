/*
 * Author: WaldoTheWarfighter
 * Redraws the purchase editor's selected icon preview.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - editor display (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoBuy_refreshPurchaseConfigIcon;
 * Locality/Authority: Curator interface client; presentation only.
 * Repeat/JIP Behaviour: Repeat-safe redraw; no JIP state.
 * Current Callers: Purchase editor load-row and icon selector controls.
 * Result: The icon preview matches the selected index.
 */

        params [["_disp", displayNull]];
        [_disp, "WaldoEcoBuy_ConfigIconIndex", "WaldoEcoBuy_ConfigIconValue"] call Waldo_fnc_EcoCore_refreshMarkerIconSelector;


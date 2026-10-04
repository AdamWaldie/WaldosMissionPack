/*
 * Author: WaldoTheWarfighter
 * Advances the Purchase editor's icon selector.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - editor display (optional, default: displayNull)
 * 1: _delta <NUMBER> - selector step (optional, default: 0)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _delta] call Waldo_fnc_EcoBuy_cyclePurchaseConfigIcon;
 * Locality/Authority: Curator interface client; local preview only.
 * Repeat/JIP Behaviour: Repeat calls advance selection; no JIP state until submission.
 * Current Callers: Purchase editor icon arrows.
 * Result: Selected icon index and preview are updated.
 */

        params [["_disp", displayNull], ["_delta", 0]];
        [_disp, _delta, "WaldoEcoBuy_ConfigIconIndex", "WaldoEcoBuy_ConfigIconValue"] call Waldo_fnc_EcoCore_cycleMarkerIconSelector;


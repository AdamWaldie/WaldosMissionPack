/*
 * Author: WaldoTheWarfighter
 * Advances the Purchase editor's faction selector.
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
 * [_disp, _delta] call Waldo_fnc_EcoBuy_cyclePurchaseConfigSide;
 * Locality/Authority: Curator interface client; local selection only.
 * Repeat/JIP Behaviour: Repeat calls advance selection; no JIP state until submission.
 * Current Callers: Purchase editor faction arrows.
 * Result: Selected faction and preview are updated.
 */

        params [["_disp", displayNull], ["_delta", 0]];

        if (isNull _disp) exitWith {};

        private _choices = call Waldo_fnc_EcoBuy_getPurchaseSideChoices;
        private _count = count _choices;
        if (_count <= 0) exitWith {};

        private _index = _disp getVariable ["WaldoEcoBuy_ConfigSideIndex", 0];
        _index = (_index + _delta) mod _count;
        if (_index < 0) then {_index = _index + _count;};
        _disp setVariable ["WaldoEcoBuy_ConfigSideIndex", _index];
        [_disp] call Waldo_fnc_EcoBuy_refreshPurchaseConfigSide;


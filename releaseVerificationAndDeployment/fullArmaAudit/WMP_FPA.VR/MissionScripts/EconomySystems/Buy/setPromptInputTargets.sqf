/*
 * Author: WaldoTheWarfighter
 * Registers Purchase form controls for keyboard focus/navigation handling.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - editor display (optional, default: displayNull)
 * 1: _targets <ARRAY> - targets (optional, default: [])
 * 2: _focusCtrl <CONTROL> - first focused input (optional, default: controlNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _targets, _focusCtrl] call Waldo_fnc_EcoBuy_setPromptInputTargets;
 * Locality/Authority: Curator interface client; local UI only.
 * Repeat/JIP Behaviour: Replaces local input targets; no JIP state.
 * Current Callers: Purchase editor creation.
 * Result: Shared prompt navigation uses the listed controls.
 */

        params [["_disp", displayNull], ["_targets", []], ["_focusCtrl", controlNull]];
        [_disp, _targets, _focusCtrl, "WaldoEcoBuy_InputTargets", [1, 14, 28, 156, 211]] call Waldo_fnc_EcoCore_setPromptInputTargets;


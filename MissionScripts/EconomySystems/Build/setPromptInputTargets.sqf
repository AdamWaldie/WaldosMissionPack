/*
 * Author: WaldoTheWarfighter
 * Registers Construction editor controls for keyboard focus/navigation.
 *
 * Part of the Waldos Economy Systems suite (Build system).
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
 * [_disp, _targets, _focusCtrl] call Waldo_fnc_EcoBuild_setPromptInputTargets;
 * Locality/Authority: Curator interface client; local UI only.
 * Repeat/JIP Behaviour: Replaces local target list; no JIP state.
 * Current Callers: Construction editor creation.
 * Result: Shared prompt navigation uses the listed controls.
 */

        params [["_disp", displayNull], ["_targets", []], ["_focusCtrl", controlNull]];
        [_disp, _targets, _focusCtrl, "WaldoEcoBuild_InputTargets", [14, 28, 156, 211]] call Waldo_fnc_EcoCore_setPromptInputTargets;


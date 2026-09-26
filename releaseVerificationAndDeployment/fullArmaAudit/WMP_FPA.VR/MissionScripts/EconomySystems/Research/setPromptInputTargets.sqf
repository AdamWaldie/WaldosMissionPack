/*
 * Author: WaldoTheWarfighter
 * Registers Research form inputs for keyboard focus/navigation handling.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - form display (optional, default: displayNull)
 * 1: _targets <ARRAY> - targets (optional, default: [])
 * 2: _focusCtrl <CONTROL> - initial focus control (optional, default: controlNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _targets, _focusCtrl] call Waldo_fnc_EcoResearch_setPromptInputTargets;
 * Locality/Authority: Curator interface client; local UI only.
 * Repeat/JIP Behaviour: Replaces the form's input-target list; no JIP UI replay.
 * Current Callers: Research editor creation.
 * Result: The shared prompt helper receives the Research form's navigation targets.
 */

        params [["_disp", displayNull], ["_targets", []], ["_focusCtrl", controlNull]];
        [_disp, _targets, _focusCtrl, "WaldoEcoResearch_InputTargets", [14, 28, 156, 211]] call Waldo_fnc_EcoCore_setPromptInputTargets;


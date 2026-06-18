/*
 * Author: Waldo
 * Set prompt input targets.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 * 1: _targets <ARRAY> - targets (optional, default: [])
 * 2: _focusCtrl <ANY> - focus ctrl (optional, default: controlNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _targets, _focusCtrl] call Waldo_fnc_EcoResource_setPromptInputTargets;
 */

    params [["_disp", displayNull], ["_targets", []], ["_focusCtrl", controlNull]];
    [_disp, _targets, _focusCtrl, "WaldoEcoResource_InputTargets", [14, 28, 156, 211]] call Waldo_fnc_EcoCore_setPromptInputTargets;

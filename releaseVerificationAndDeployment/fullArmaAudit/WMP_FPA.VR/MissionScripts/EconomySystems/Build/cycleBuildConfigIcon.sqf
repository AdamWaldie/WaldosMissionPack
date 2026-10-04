/*
 * Author: WaldoTheWarfighter
 * Advances the Construction editor's marker icon selector.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - editor display
 * 1: _delta <NUMBER> - selector step (optional, default: 0)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _delta] call Waldo_fnc_EcoBuild_cycleBuildConfigIcon;
 * Locality/Authority: Curator interface client; local preview only.
 * Repeat/JIP Behaviour: Repeat calls advance selection; no JIP state until submission.
 * Current Callers: Construction editor icon arrows.
 * Result: Icon selection and preview move by the requested step.
 */

        params ["_disp", ["_delta", 0]];
        [_disp, _delta, "WaldoEcoBuild_ConfigIconIndex", "WaldoEcoBuild_ConfigIconValue"] call Waldo_fnc_EcoCore_cycleMarkerIconSelector;


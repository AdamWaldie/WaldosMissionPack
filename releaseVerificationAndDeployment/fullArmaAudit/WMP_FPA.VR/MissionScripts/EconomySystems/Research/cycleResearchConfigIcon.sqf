/*
 * Author: WaldoTheWarfighter
 * Moves the Research editor's icon selector by the requested step.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - Research editor display
 * 1: _delta <NUMBER> - selector step (optional, default: 0)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _delta] call Waldo_fnc_EcoResearch_cycleResearchConfigIcon;
 * Locality/Authority: Curator interface client only; changes local selection.
 * Repeat/JIP Behaviour: Repeated calls advance selection; no server/JIP state until submission.
 * Current Callers: Research editor icon arrow controls.
 * Result: The displayed icon changes to the next available choice.
 */

        params ["_disp", ["_delta", 0]];
        [_disp, _delta, "WaldoEcoResearch_ConfigIconIndex", "WaldoEcoResearch_ConfigIconValue"] call Waldo_fnc_EcoCore_cycleMarkerIconSelector;


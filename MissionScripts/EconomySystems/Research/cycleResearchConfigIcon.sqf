/*
 * Author: Waldo
 * Cycle research config icon.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp
 * 1: _delta <SCALAR> - delta (optional, default: 0)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _delta] call Waldo_fnc_EcoResearch_cycleResearchConfigIcon;
 */

        params ["_disp", ["_delta", 0]];
        [_disp, _delta, "WaldoEcoResearch_ConfigIconIndex", "WaldoEcoResearch_ConfigIconValue"] call Waldo_fnc_EcoCore_cycleMarkerIconSelector;


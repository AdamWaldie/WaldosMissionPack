/*
 * Author: Waldo
 * Refresh research config icon.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoResearch_refreshResearchConfigIcon;
 */

        params ["_disp"];
        [_disp, "WaldoEcoResearch_ConfigIconIndex", "WaldoEcoResearch_ConfigIconValue"] call Waldo_fnc_EcoCore_refreshMarkerIconSelector;


/*
 * Author: WaldoTheWarfighter
 * Refreshes the Research editor's icon preview from its selected index.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - Research editor display
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoResearch_refreshResearchConfigIcon;
 * Locality/Authority: Curator interface client; presentation only.
 * Repeat/JIP Behaviour: Repeat-safe local redraw; no JIP state.
 * Current Callers: Research editor load-row and icon selector actions.
 * Result: The preview matches the selected icon entry.
 */

        params ["_disp"];
        [_disp, "WaldoEcoResearch_ConfigIconIndex", "WaldoEcoResearch_ConfigIconValue"] call Waldo_fnc_EcoCore_refreshMarkerIconSelector;


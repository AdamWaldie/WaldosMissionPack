/*
 * Author: Waldo
 * Begin research center placement.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _display <ANY> - display
 * 1: _pos <ANY> - pos
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_display, _pos] call Waldo_fnc_EcoResearch_beginResearchCenterPlacement;
 */

        if (!hasInterface) exitWith {};

        private _disp = call Waldo_fnc_EcoCore_getZeusDisplay;
        if (isNull _disp) exitWith {};

        [_disp] call Waldo_fnc_EcoResearch_cleanupResearchConfigPrompt;

        if (!isNil "Waldo_fnc_EcoResource_stopResourceCratePlacement") then {
            [_disp] call Waldo_fnc_EcoResource_stopResourceCratePlacement;
        };

        [_disp] call Waldo_fnc_EcoResearch_stopResearchCenterPlacement;

        [
            _disp,
            "WaldoEcoResearch_PlacementPending",
            "WaldoEcoResearch_PlacementEH",
            "WaldoEcoResearch_PlacementKeyEH",
            {
                call Waldo_fnc_EcoResearch_getPlacementPos
            },
            {
                params ["_display", "_pos"];
                [_pos] call Waldo_fnc_EcoResearch_spawnResearchCenter;
            }
        ] call Waldo_fnc_EcoCore_beginZeusPlacementSession;


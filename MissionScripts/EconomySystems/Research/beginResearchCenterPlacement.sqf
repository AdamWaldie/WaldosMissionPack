/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - beginResearchCenterPlacement
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_beginResearchCenterPlacement via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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


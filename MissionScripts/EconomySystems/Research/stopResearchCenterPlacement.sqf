/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - stopResearchCenterPlacement
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_stopResearchCenterPlacement via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        [
            _disp,
            "WaldoEcoResearch_PlacementPending",
            "WaldoEcoResearch_PlacementEH",
            "WaldoEcoResearch_PlacementKeyEH"
        ] call Waldo_fnc_EcoCore_stopZeusPlacementSession;


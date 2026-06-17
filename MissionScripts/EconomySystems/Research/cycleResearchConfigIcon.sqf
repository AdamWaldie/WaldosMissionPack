/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - cycleResearchConfigIcon
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_cycleResearchConfigIcon via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_disp", ["_delta", 0]];
        [_disp, _delta, "WaldoEcoResearch_ConfigIconIndex", "WaldoEcoResearch_ConfigIconValue"] call Waldo_fnc_EcoCore_cycleMarkerIconSelector;


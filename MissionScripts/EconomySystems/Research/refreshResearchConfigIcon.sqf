/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - refreshResearchConfigIcon
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_refreshResearchConfigIcon via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_disp"];
        [_disp, "WaldoEcoResearch_ConfigIconIndex", "WaldoEcoResearch_ConfigIconValue"] call Waldo_fnc_EcoCore_refreshMarkerIconSelector;


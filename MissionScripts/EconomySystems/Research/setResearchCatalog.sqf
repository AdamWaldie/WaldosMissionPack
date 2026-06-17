/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - setResearchCatalog
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_setResearchCatalog via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_catalog", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoResearch_ResearchCatalog", [_catalog] call Waldo_fnc_EcoResearch_normalizeResearchCatalog, true];


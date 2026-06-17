/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - setResearchCatalogLocal
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_setResearchCatalogLocal via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_catalog", []]];
        missionNamespace setVariable ["WaldoEcoResearch_ResearchCatalog", [_catalog] call Waldo_fnc_EcoResearch_normalizeResearchCatalog];


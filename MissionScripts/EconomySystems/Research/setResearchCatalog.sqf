/*
 * Author: Waldo
 * Set research catalog.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _catalog <ARRAY> - catalog (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_catalog] call Waldo_fnc_EcoResearch_setResearchCatalog;
 */

        params [["_catalog", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoResearch_ResearchCatalog", [_catalog] call Waldo_fnc_EcoResearch_normalizeResearchCatalog, true];


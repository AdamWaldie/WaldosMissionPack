/*
 * Author: Waldo
 * Set research catalog local.
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
 * [_catalog] call Waldo_fnc_EcoResearch_setResearchCatalogLocal;
 */

        params [["_catalog", []]];
        missionNamespace setVariable ["WaldoEcoResearch_ResearchCatalog", [_catalog] call Waldo_fnc_EcoResearch_normalizeResearchCatalog];


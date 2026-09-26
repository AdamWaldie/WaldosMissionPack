/*
 * Author: WaldoTheWarfighter
 * Stores a normalized Research catalog on this machine without broadcasting it.
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
 * Locality/Authority: Local cache update only; not the authoritative public setter.
 * Repeat/JIP Behaviour: Replaces local cache; a JIP client must receive a server snapshot separately.
 * Current Callers: Research curator prompt edits before server submission.
 * Result: Later local catalog reads use the normalized rows.
 */

        params [["_catalog", []]];
        missionNamespace setVariable ["WaldoEcoResearch_ResearchCatalog", [_catalog] call Waldo_fnc_EcoResearch_normalizeResearchCatalog];


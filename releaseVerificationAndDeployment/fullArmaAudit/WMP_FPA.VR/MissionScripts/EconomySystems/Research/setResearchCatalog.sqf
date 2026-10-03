/*
 * Author: WaldoTheWarfighter
 * Normalizes and publishes the side-independent Research technology catalog.
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
 * Locality/Authority: Economy authority only; clients receive the published catalog.
 * Repeat/JIP Behaviour: Repeated calls replace the catalog; JIP clients receive the latest value.
 * Current Callers: Research ZEN configuration and exported mission setup calls.
 * Result: Invalid entries are normalized before the catalog becomes public.
 */

        params [["_catalog", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoResearch_ResearchCatalog", [_catalog] call Waldo_fnc_EcoResearch_normalizeResearchCatalog, true];


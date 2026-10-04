/*
 * Author: WaldoTheWarfighter
 * Reads a copy of the current Research technology catalog.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <ARRAY> catalog rows; [] when no catalog has been published.
 *
 * Example:
 * [] call Waldo_fnc_EcoResearch_getResearchCatalog;
 * Locality/Authority: Any machine; reads the public catalog without changing it.
 * Repeat/JIP Behaviour: Repeat-safe read; JIP receives the published catalog.
 * Current Callers: Research validation, authoring, status and export helpers.
 * Result: Returns a copy so callers do not mutate the stored catalog by reference.
 */

        +(missionNamespace getVariable ["WaldoEcoResearch_ResearchCatalog", []])


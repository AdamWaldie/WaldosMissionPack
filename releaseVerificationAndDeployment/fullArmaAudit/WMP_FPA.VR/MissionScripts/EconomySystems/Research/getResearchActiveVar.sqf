/*
 * Author: WaldoTheWarfighter
 * Resolves the missionNamespace active-research variable for one side.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - WEST/EAST/GUER/CIV side key
 *
 * Return Value:
 * <STRING> variable name, or "" for an unknown side.
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoResearch_getResearchActiveVar;
 * Locality/Authority: Any machine; pure side-to-key lookup.
 * Repeat/JIP Behaviour: Stateless; no JIP replay is needed.
 * Current Callers: Research active-state get/set helpers.
 * Result: Returns the side-specific active-research storage key.
 */

        params ["_sideKey"];

        switch (toUpper _sideKey) do {
            case "WEST": {"WaldoEcoResearch_ResearchActive_WEST"};
            case "EAST": {"WaldoEcoResearch_ResearchActive_EAST"};
            case "GUER": {"WaldoEcoResearch_ResearchActive_GUER"};
            case "CIV": {"WaldoEcoResearch_ResearchActive_CIV"};
            default {""};
        };


/*
 * Author: WaldoTheWarfighter
 * Resolves the missionNamespace completed-research variable for one side.
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
 * [_sideKey] call Waldo_fnc_EcoResearch_getResearchStateVar;
 * Locality/Authority: Any machine; pure side-to-key lookup.
 * Repeat/JIP Behaviour: Stateless; no JIP replay is needed.
 * Current Callers: Research completed-state get/set helpers.
 * Result: Returns the side-specific completed-research storage key.
 */

        params ["_sideKey"];

        switch (toUpper _sideKey) do {
            case "WEST": {"WaldoEcoResearch_ResearchDone_WEST"};
            case "EAST": {"WaldoEcoResearch_ResearchDone_EAST"};
            case "GUER": {"WaldoEcoResearch_ResearchDone_GUER"};
            case "CIV": {"WaldoEcoResearch_ResearchDone_CIV"};
            default {""};
        };


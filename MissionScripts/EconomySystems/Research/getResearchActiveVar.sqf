/*
 * Author: Waldo
 * Get research active var.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoResearch_getResearchActiveVar;
 */

        params ["_sideKey"];

        switch (toUpper _sideKey) do {
            case "WEST": {"WaldoEcoResearch_ResearchActive_WEST"};
            case "EAST": {"WaldoEcoResearch_ResearchActive_EAST"};
            case "GUER": {"WaldoEcoResearch_ResearchActive_GUER"};
            case "CIV": {"WaldoEcoResearch_ResearchActive_CIV"};
            default {""};
        };


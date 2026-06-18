/*
 * Author: Waldo
 * Get research state var.
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
 * [_sideKey] call Waldo_fnc_EcoResearch_getResearchStateVar;
 */

        params ["_sideKey"];

        switch (toUpper _sideKey) do {
            case "WEST": {"WaldoEcoResearch_ResearchDone_WEST"};
            case "EAST": {"WaldoEcoResearch_ResearchDone_EAST"};
            case "GUER": {"WaldoEcoResearch_ResearchDone_GUER"};
            case "CIV": {"WaldoEcoResearch_ResearchDone_CIV"};
            default {""};
        };


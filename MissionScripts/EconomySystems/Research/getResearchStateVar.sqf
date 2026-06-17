/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - getResearchStateVar
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_getResearchStateVar via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_sideKey"];

        switch (toUpper _sideKey) do {
            case "WEST": {"WaldoEcoResearch_ResearchDone_WEST"};
            case "EAST": {"WaldoEcoResearch_ResearchDone_EAST"};
            case "GUER": {"WaldoEcoResearch_ResearchDone_GUER"};
            case "CIV": {"WaldoEcoResearch_ResearchDone_CIV"};
            default {""};
        };


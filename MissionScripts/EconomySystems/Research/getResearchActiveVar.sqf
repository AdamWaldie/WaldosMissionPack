/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - getResearchActiveVar
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_getResearchActiveVar via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_sideKey"];

        switch (toUpper _sideKey) do {
            case "WEST": {"WaldoEcoResearch_ResearchActive_WEST"};
            case "EAST": {"WaldoEcoResearch_ResearchActive_EAST"};
            case "GUER": {"WaldoEcoResearch_ResearchActive_GUER"};
            case "CIV": {"WaldoEcoResearch_ResearchActive_CIV"};
            default {""};
        };


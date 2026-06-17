/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - parseResearchExclusivesText
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_parseResearchExclusivesText via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_text", ""]];
        [[_text] call Waldo_fnc_EcoCore_parseNameListText] call Waldo_fnc_EcoResearch_normalizeResearchExclusives


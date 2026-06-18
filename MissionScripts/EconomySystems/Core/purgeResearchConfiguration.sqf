/*
 * Author: Waldo
 * Purge research configuration.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_purgeResearchConfiguration;
 */

    if (!isNil "Waldo_fnc_EcoResearch_setResearchCatalog") then {
        [[]] call Waldo_fnc_EcoResearch_setResearchCatalog;
    };

/*
 * Author: Waldo
 * Purge build configuration.
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
 * [] call Waldo_fnc_EcoCore_purgeBuildConfiguration;
 */

    if (!isNil "Waldo_fnc_EcoBuild_setBuildCatalog") then {
        [[]] call Waldo_fnc_EcoBuild_setBuildCatalog;
    };

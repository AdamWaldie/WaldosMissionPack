/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - purgeResearchConfiguration
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_purgeResearchConfiguration via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if (!isNil "Waldo_fnc_EcoResearch_setResearchCatalog") then {
        [[]] call Waldo_fnc_EcoResearch_setResearchCatalog;
    };

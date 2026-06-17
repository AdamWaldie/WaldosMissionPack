/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - setBuildCatalogLocal
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_setBuildCatalogLocal via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_catalog", []]];
        missionNamespace setVariable ["WaldoEcoBuild_BuildCatalog", [_catalog] call Waldo_fnc_EcoBuild_normalizeBuildCatalog];


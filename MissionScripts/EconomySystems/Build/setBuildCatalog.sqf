/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - setBuildCatalog
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_setBuildCatalog via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_catalog", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuild_BuildCatalog", [_catalog] call Waldo_fnc_EcoBuild_normalizeBuildCatalog, true];


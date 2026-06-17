/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - setSpawnedBuildings
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_setSpawnedBuildings via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_rows", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuild_SpawnedBuildings", _rows, true];


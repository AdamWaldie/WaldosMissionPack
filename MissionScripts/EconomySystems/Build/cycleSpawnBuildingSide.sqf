/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - cycleSpawnBuildingSide
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_cycleSpawnBuildingSide via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_disp", ["_delta", 0]];

        if (isNull _disp) exitWith {};
        _disp setVariable ["WaldoEcoBuild_SpawnSideIndex", (_disp getVariable ["WaldoEcoBuild_SpawnSideIndex", 0]) + _delta];
        [_disp] call Waldo_fnc_EcoBuild_refreshSpawnBuildingSide;


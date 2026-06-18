/*
 * Author: Waldo
 * Set spawned buildings.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _rows <ARRAY> - rows (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_rows] call Waldo_fnc_EcoBuild_setSpawnedBuildings;
 */

        params [["_rows", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuild_SpawnedBuildings", _rows, true];


/*
 * Author: Waldo
 * Cycle spawn building side.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp
 * 1: _delta <SCALAR> - delta (optional, default: 0)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _delta] call Waldo_fnc_EcoBuild_cycleSpawnBuildingSide;
 */

        params ["_disp", ["_delta", 0]];

        if (isNull _disp) exitWith {};
        _disp setVariable ["WaldoEcoBuild_SpawnSideIndex", (_disp getVariable ["WaldoEcoBuild_SpawnSideIndex", 0]) + _delta];
        [_disp] call Waldo_fnc_EcoBuild_refreshSpawnBuildingSide;


/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getEstimatedDurationSeconds
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getEstimatedDurationSeconds via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_baseTime", 60], ["_bonusPercent", 0]];

        private _time = 1 max _baseTime;
        private _multiplier = 1 + ((0 max _bonusPercent) / 100);
        _time / _multiplier


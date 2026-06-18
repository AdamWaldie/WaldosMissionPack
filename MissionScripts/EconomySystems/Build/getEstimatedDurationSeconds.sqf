/*
 * Author: Waldo
 * Get estimated duration seconds.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _baseTime <SCALAR> - base time (optional, default: 60)
 * 1: _bonusPercent <SCALAR> - bonus percent (optional, default: 0)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_baseTime, _bonusPercent] call Waldo_fnc_EcoBuild_getEstimatedDurationSeconds;
 */

        params [["_baseTime", 60], ["_bonusPercent", 0]];

        private _time = 1 max _baseTime;
        private _multiplier = 1 + ((0 max _bonusPercent) / 100);
        _time / _multiplier


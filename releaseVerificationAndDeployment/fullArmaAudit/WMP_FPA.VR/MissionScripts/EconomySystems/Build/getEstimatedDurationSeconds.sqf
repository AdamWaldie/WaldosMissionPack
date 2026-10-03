/*
 * Author: WaldoTheWarfighter
 * Reduces a base job duration by a side's percentage speed bonus.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _baseTime <NUMBER> - seconds (optional, default: 60)
 * 1: _bonusPercent <NUMBER> - percent (optional, default: 0)
 *
 * Return Value:
 * <NUMBER> estimated seconds, with base time clamped to at least one.
 *
 * Example:
 * [_baseTime, _bonusPercent] call Waldo_fnc_EcoBuild_getEstimatedDurationSeconds;
 * Locality/Authority: Any machine; pure arithmetic.
 * Repeat/JIP Behaviour: Stateless; no JIP effect.
 * Current Callers: No in-pack caller; available to mission scripts estimating Economy jobs.
 * Result: A 100 percent bonus halves the baseline estimate.
 */

        params [["_baseTime", 60], ["_bonusPercent", 0]];

        private _time = 1 max _baseTime;
        private _multiplier = 1 + ((0 max _bonusPercent) / 100);
        _time / _multiplier


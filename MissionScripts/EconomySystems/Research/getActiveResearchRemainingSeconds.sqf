/*
 * Author: Waldo
 * Get active research remaining seconds.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "NONE")
 * 1: _activeRow <ARRAY> - active row (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey, _activeRow] call Waldo_fnc_EcoResearch_getActiveResearchRemainingSeconds;
 */

        params [["_sideKey", "NONE"], ["_activeRow", []]];

        private _active = if ((count _activeRow) > 0) then {_activeRow} else {[_sideKey] call Waldo_fnc_EcoResearch_getSideActiveResearch};
        if ((count _active) <= 0) exitWith {0};

        if ((count _active) >= 5) exitWith {
            private _required = 1 max (_active param [1, 60]);
            private _baseProgress = 0 max (_active param [2, 0]);
            private _bonusProgress = 0 max (_active param [3, 0]);
            private _remainingEquivalent = 0 max (_required - (_baseProgress + _bonusProgress));
            private _bonusPct = if (!isNil "Waldo_fnc_EcoBuild_getSideResearchSpeedBonusPercent") then {[_sideKey] call Waldo_fnc_EcoBuild_getSideResearchSpeedBonusPercent} else {0};
            ceil (_remainingEquivalent / (1 + ((0 max _bonusPct) / 100)))
        };

        0 max ceil ((_active param [1, serverTime]) - serverTime)


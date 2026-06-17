/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - progressResearchQueue
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_progressResearchQueue via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        {
            private _sideKey = _x;
            private _active = [_sideKey] call Waldo_fnc_EcoResearch_getSideActiveResearch;
            if ((count _active) <= 0) then {continue;};

            private _researchName = _active param [0, ""];
            if (_researchName isEqualTo "") then {
                [_sideKey, []] call Waldo_fnc_EcoResearch_setSideActiveResearch;
                continue;
            };

            if ((count _active) >= 5) then {
                private _required = 1 max (_active param [1, 60]);
                private _baseProgress = 0 max (_active param [2, 0]);
                private _bonusProgress = 0 max (_active param [3, 0]);
                private _lastTick = _active param [4, serverTime];
                private _delta = 0 max (serverTime - _lastTick);
                private _bonusPct = if (!isNil "Waldo_fnc_EcoBuild_getSideResearchSpeedBonusPercent") then {[_sideKey] call Waldo_fnc_EcoBuild_getSideResearchSpeedBonusPercent} else {0};

                _baseProgress = _baseProgress + _delta;
                _bonusProgress = _bonusProgress + (_delta * ((0 max _bonusPct) / 100));

                if ((_baseProgress + _bonusProgress) >= _required) then {
                    [_sideKey, _researchName, true] call Waldo_fnc_EcoResearch_setResearchCompletedForSide;
                    [_sideKey, []] call Waldo_fnc_EcoResearch_setSideActiveResearch;
                } else {
                    [_sideKey, [_researchName, _required, _baseProgress, _bonusProgress, serverTime]] call Waldo_fnc_EcoResearch_setSideActiveResearch;
                };
            } else {
                private _endTime = _active param [1, -1];
                if (serverTime >= _endTime) then {
                    [_sideKey, _researchName, true] call Waldo_fnc_EcoResearch_setResearchCompletedForSide;
                    [_sideKey, []] call Waldo_fnc_EcoResearch_setSideActiveResearch;
                };
            };
        } forEach ["WEST", "EAST", "GUER", "CIV"];


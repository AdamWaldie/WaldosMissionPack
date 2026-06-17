/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - progressUpgradeJobs
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_progressUpgradeJobs via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        private _runtimeRows = call Waldo_fnc_EcoBuild_getUpgradeJobRuntime;
        private _kept = [];

        {
            private _jobId = _x param [0, ""];
            private _sourceBuilding = _x param [1, objNull];
            private _targetName = _x param [2, ""];
            private _sideKey = _x param [3, "NONE"];
            private _required = 1 max (_x param [4, 60]);
            private _baseProgress = 0 max (_x param [5, 0]);
            private _bonusProgress = 0 max (_x param [6, 0]);
            private _lastTick = _x param [7, serverTime];

            if (isNull _sourceBuilding) then {continue;};

            private _delta = 0 max (serverTime - _lastTick);
            private _bonusPct = [_sideKey] call Waldo_fnc_EcoBuild_getSideBuildSpeedBonusPercent;

            _baseProgress = _baseProgress + _delta;
            _bonusProgress = _bonusProgress + (_delta * ((0 max _bonusPct) / 100));

            if ((_baseProgress + _bonusProgress) >= _required) then {
                private _spawnPos = getPosATL _sourceBuilding;
                private _spawnDir = getDir _sourceBuilding;
                deleteVehicle _sourceBuilding;
                [_spawnPos, _targetName, _sideKey, _spawnDir] call Waldo_fnc_EcoBuild_spawnConfiguredBuilding;
            } else {
                _kept pushBack [
                    _jobId,
                    _sourceBuilding,
                    _targetName,
                    _sideKey,
                    _required,
                    _baseProgress,
                    _bonusProgress,
                    serverTime
                ];
            };
        } forEach _runtimeRows;

        [_kept] call Waldo_fnc_EcoBuild_setUpgradeJobRuntime;


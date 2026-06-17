/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - progressConstructionJobs
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_progressConstructionJobs via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        private _runtimeRows = call Waldo_fnc_EcoBuild_getConstructionJobRuntime;
        private _kept = [];

        {
            private _jobId = _x param [0, ""];
            private _siteItems = _x param [1, []];
            private _pos = _x param [2, [0, 0, 0]];
            private _dir = _x param [3, 0];
            private _buildName = _x param [4, ""];
            private _sideKey = _x param [5, "NONE"];
            private _required = 1 max (_x param [6, 60]);
            private _baseProgress = 0 max (_x param [7, 0]);
            private _bonusProgress = 0 max (_x param [8, 0]);
            private _lastTick = _x param [9, serverTime];
            private _delta = 0 max (serverTime - _lastTick);
            private _bonusPct = [_sideKey] call Waldo_fnc_EcoBuild_getSideBuildSpeedBonusPercent;

            _baseProgress = _baseProgress + _delta;
            _bonusProgress = _bonusProgress + (_delta * ((0 max _bonusPct) / 100));

            if ((_baseProgress + _bonusProgress) >= _required) then {
                [_siteItems] call Waldo_fnc_EcoBuild_deleteConstructionSite;
                [_jobId] call Waldo_fnc_EcoBuild_unregisterConstructionJob;
                [_pos, _buildName, _sideKey, _dir] call Waldo_fnc_EcoBuild_spawnConfiguredBuilding;
            } else {
                _kept pushBack [
                    _jobId,
                    _siteItems,
                    _pos,
                    _dir,
                    _buildName,
                    _sideKey,
                    _required,
                    _baseProgress,
                    _bonusProgress,
                    serverTime
                ];
            };
        } forEach _runtimeRows;

        [_kept] call Waldo_fnc_EcoBuild_setConstructionJobRuntime;


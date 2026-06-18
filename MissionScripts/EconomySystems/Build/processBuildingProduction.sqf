/*
 * Author: Waldo
 * Process building production.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoBuild_processBuildingProduction;
 */

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        private _rows = call Waldo_fnc_EcoBuild_getSpawnedBuildings;
        private _kept = [];

        {
            private _building = _x;
            if (isNull _building) then {
                continue;
            };

            private _buildName = _building getVariable ["WaldoEcoBuild_BuildDefinitionName", ""];
            private _entry = [_buildName] call Waldo_fnc_EcoBuild_getBuildDefinition;
            if ((count _entry) <= 0) then {
                _kept pushBack _building;
                continue;
            };

            private _sideKey = _building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"];
            private _resourceType = _entry param [9, ""];
            private _amount = _entry param [10, 0];
            private _interval = _entry param [11, 0];
            private _upkeepCosts = _entry param [15, []];
            private _upkeepInterval = _entry param [16, 0];
            private _lastProductionTick = _building getVariable ["WaldoEcoBuild_BuildLastProduction", serverTime];
            private _lastUpkeepTick = _building getVariable ["WaldoEcoBuild_BuildLastUpkeep", serverTime];
            private _lastDetectionTick = _building getVariable ["WaldoEcoBuild_LastDetectionScan", serverTime];
            private _manualDisabled = _building getVariable ["WaldoEcoBuild_ManualDisabled", false];
            private _isUpgrading = _building getVariable ["WaldoEcoBuild_IsUpgrading", false];
            private _previousOperational = _building getVariable ["WaldoEcoBuild_Operational", true];
            private _operational = _building getVariable ["WaldoEcoBuild_Operational", true];
            private _disabledReason = _building getVariable ["WaldoEcoBuild_DisabledReason", ""];
            private _detectorRange = 0 max (_entry param [14, 0]);
            private _usesTimedUpkeep = (_sideKey in ["WEST", "EAST", "GUER"]) && {(count _upkeepCosts) > 0} && {_upkeepInterval > 0};
            private _detectorInterval = if (_usesTimedUpkeep) then {_upkeepInterval} else {60};
            private _paidUpkeepThisTick = false;
            private _productionDue =
                (_sideKey in ["WEST", "EAST", "GUER"])
                && {_resourceType isNotEqualTo ""}
                && {_amount > 0}
                && {_interval > 0}
                && {(serverTime - _lastProductionTick) >= _interval};
            private _allowedProduction = if (_productionDue) then {
                [_sideKey, _resourceType, _amount] call Waldo_fnc_EcoResource_getAllowedResourceGain
            } else {
                0
            };
            private _skipUpkeepForFullStorage = _productionDue && {_allowedProduction <= 0};

            if (_manualDisabled) then {
                _operational = false;
                _disabledReason = "Building manually disabled.";
                _building setVariable ["WaldoEcoBuild_Operational", false, true];
                _building setVariable ["WaldoEcoBuild_DisabledReason", _disabledReason, true];
                if (_detectorRange > 0) then {
                    [_building] call Waldo_fnc_EcoBuild_cleanupDetectorVisuals;
                    _building setVariable ["WaldoEcoBuild_LastDetectionScan", serverTime, false];
                };
                if (_previousOperational) then {
                    [_building] call Waldo_fnc_EcoBuild_refreshBuildingMarker;
                };
                _kept pushBack _building;
                continue;
            };

            if (_isUpgrading) then {
                _operational = false;
                _disabledReason = format ["Upgrading to %1.", _building getVariable ["WaldoEcoBuild_UpgradeTargetName", ""]];
                _building setVariable ["WaldoEcoBuild_Operational", false, true];
                _building setVariable ["WaldoEcoBuild_DisabledReason", _disabledReason, true];
                if (_detectorRange > 0) then {
                    [_building] call Waldo_fnc_EcoBuild_cleanupDetectorVisuals;
                    _building setVariable ["WaldoEcoBuild_LastDetectionScan", serverTime, false];
                };
                if (_previousOperational) then {
                    [_building] call Waldo_fnc_EcoBuild_refreshBuildingMarker;
                };
                _kept pushBack _building;
                continue;
            };

            if ((_sideKey in ["WEST", "EAST", "GUER"]) && {(count _upkeepCosts) > 0} && {_upkeepInterval > 0} && {(serverTime - _lastUpkeepTick) >= _upkeepInterval}) then {
                if (_skipUpkeepForFullStorage) then {
                    _operational = true;
                    _disabledReason = "";
                } else {
                    _operational = true;
                    _disabledReason = "";
                    {
                        private _resourceName = _x param [0, ""];
                        private _resourceValue = _x param [1, 0];
                        private _available = [_sideKey, _resourceName] call Waldo_fnc_EcoResource_getSideResourceAmount;
                        if (_available < _resourceValue) exitWith {
                            _operational = false;
                            _disabledReason = format ["Building Disabled due to lack of %1.", _resourceName];
                        };
                    } forEach _upkeepCosts;

                    if (_operational) then {
                        {
                            private _resourceName = _x param [0, ""];
                            private _resourceValue = _x param [1, 0];
                            [_sideKey, _resourceName, -_resourceValue, _buildName] call Waldo_fnc_EcoResource_addSideResourceAmount;
                        } forEach _upkeepCosts;
                        _building setVariable ["WaldoEcoBuild_BuildLastUpkeep", serverTime, false];
                        _paidUpkeepThisTick = true;
                    };
                };
            };

            if ((_sideKey in ["WEST", "EAST", "GUER"]) && {(count _upkeepCosts) <= 0 || {_upkeepInterval <= 0}}) then {
                _operational = true;
                _disabledReason = "";
            };

            _building setVariable ["WaldoEcoBuild_Operational", _operational, true];
            _building setVariable ["WaldoEcoBuild_DisabledReason", _disabledReason, true];
            if (_operational isNotEqualTo _previousOperational) then {
                [_building] call Waldo_fnc_EcoBuild_refreshBuildingMarker;
            };

            if (
                (_detectorRange <= 0)
                || {!(_sideKey in ["WEST", "EAST", "GUER"])}
                || {!_operational}
            ) then {
                if (
                    (_building getVariable ["WaldoEcoBuild_DetectorAreaMarker", ""]) isNotEqualTo ""
                    || {(count (_building getVariable ["WaldoEcoBuild_DetectorContactMarkers", []])) > 0}
                ) then {
                    [_building] call Waldo_fnc_EcoBuild_cleanupDetectorVisuals;
                    _building setVariable ["WaldoEcoBuild_LastDetectionScan", serverTime, false];
                };
            } else {
                private _shouldRunDetectorScan = false;
                if (_usesTimedUpkeep) then {
                    _shouldRunDetectorScan = _paidUpkeepThisTick;
                } else {
                    _shouldRunDetectorScan = (serverTime - _lastDetectionTick) >= _detectorInterval;
                };

                if (_shouldRunDetectorScan) then {
                    [_building, _entry] call Waldo_fnc_EcoBuild_scanDetectorBuilding;
                };
            };

            if (_operational && {_productionDue} && {_allowedProduction > 0}) then {
                [_sideKey, _resourceType, _amount, _buildName] call Waldo_fnc_EcoResource_addSideResourceAmount;
                _building setVariable ["WaldoEcoBuild_BuildLastProduction", serverTime, false];
            };

            _kept pushBack _building;
        } forEach _rows;

        [_kept] call Waldo_fnc_EcoBuild_setSpawnedBuildings;


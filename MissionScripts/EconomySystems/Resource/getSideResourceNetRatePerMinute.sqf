/*
 * Author: Waldo
 * Get side resource net rate per minute.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _resourceType <ANY> - resource type
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey, _resourceType] call Waldo_fnc_EcoResource_getSideResourceNetRatePerMinute;
 */

    params ["_sideKey", "_resourceType"];

    private _net = 0;
    private _capacity = [_sideKey, _resourceType] call Waldo_fnc_EcoResource_getSideResourceStorageCapacity;
    private _remainingHeadroom = if (_capacity < 0) then {
        -1
    } else {
        0 max (_capacity - ([_sideKey, _resourceType] call Waldo_fnc_EcoResource_getSideResourceAmount))
    };

    {
        private _zone = _x;
        if ((_zone param [5, "NONE"]) isNotEqualTo _sideKey) then {continue;};

        private _interval = 1 max (floor (_zone param [7, 60]));
        {
            private _row = _x;
            if ((_row param [0, ""]) isNotEqualTo _resourceType) then {continue;};

            private _cycleAmount = 0 max (floor (_row param [1, 0]));
            private _depositRemaining = floor (_row param [2, -1]);
            private _depositTotal = floor (_row param [3, -1]);
            if (_depositTotal > 0) then {
                if (_depositRemaining <= 0) then {continue;};
                _cycleAmount = _cycleAmount min _depositRemaining;
            };

            private _appliedAmount = if (_remainingHeadroom < 0) then {
                _cycleAmount
            } else {
                _cycleAmount min _remainingHeadroom
            };

            if (_appliedAmount > 0) then {
                _net = _net + ((_appliedAmount * 60) / _interval);
                if (_remainingHeadroom >= 0) then {
                    _remainingHeadroom = 0 max (_remainingHeadroom - _appliedAmount);
                };
            };
        } forEach ([_zone] call Waldo_fnc_EcoResource_getZoneResourceRows);
    } forEach (call Waldo_fnc_EcoResource_getResourceZones);

    if (!isNil "Waldo_fnc_EcoBuild_getSpawnedBuildings" && {!isNil "Waldo_fnc_EcoBuild_getBuildDefinition"}) then {
        {
            private _building = _x;
            if (isNull _building) then {continue;};
            if ((_building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"]) isNotEqualTo _sideKey) then {continue;};
            if !(_building getVariable ["WaldoEcoBuild_Operational", true]) then {continue;};

            private _entry = [_building getVariable ["WaldoEcoBuild_BuildDefinitionName", ""]] call Waldo_fnc_EcoBuild_getBuildDefinition;
            if ((count _entry) <= 0) then {continue;};

            private _produceResource = _entry param [9, ""];
            private _produceAmount = 0 max (floor (_entry param [10, 0]));
            private _produceInterval = 1 max (floor (_entry param [11, 0]));
            private _upkeepRows = _entry param [15, []];
            private _upkeepInterval = 0 max (floor (_entry param [16, 0]));
            private _skipUpkeep = false;

            if (_produceResource isNotEqualTo "" && {_produceAmount > 0} && {(_entry param [11, 0]) > 0}) then {
                if (_produceResource isEqualTo _resourceType) then {
                    private _appliedAmount = if (_remainingHeadroom < 0) then {
                        _produceAmount
                    } else {
                        _produceAmount min _remainingHeadroom
                    };

                    if (_appliedAmount > 0) then {
                        _net = _net + ((_appliedAmount * 60) / _produceInterval);
                        if (_remainingHeadroom >= 0) then {
                            _remainingHeadroom = 0 max (_remainingHeadroom - _appliedAmount);
                        };
                    } else {
                        _skipUpkeep = true;
                    };
                } else {
                    _skipUpkeep = ([_sideKey, _produceResource, _produceAmount] call Waldo_fnc_EcoResource_getAllowedResourceGain) <= 0;
                };
            };

            if (!_skipUpkeep && {_upkeepInterval > 0}) then {
                {
                    private _row = _x;
                    if ((_row param [0, ""]) isEqualTo _resourceType) then {
                        _net = _net - (((0 max (floor (_row param [1, 0]))) * 60) / _upkeepInterval);
                    };
                } forEach _upkeepRows;
            };
        } forEach (call Waldo_fnc_EcoBuild_getSpawnedBuildings);
    };

    _net

/*
 * Author: Waldo
 * Generate zone resources.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoResource_generateZoneResources;
 */

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _zones = call Waldo_fnc_EcoResource_getResourceZones;
    private _changed = false;
    private _markersToRefresh = [];
    private _expiredZoneIds = [];

    {
        private _zone = _x;
        private _zoneId = _zone param [0, ""];
        private _anchor = _zone param [10, objNull];
        private _owner = _zone param [5, "NONE"];
        private _interval = _zone param [7, 60];
        private _lastTick = _zone param [8, 0];

        if (!isNull _anchor) then {
            private _anchorPos = getPosATL _anchor;
            if ((_anchorPos distance2D (_zone param [2, [0, 0, 0]])) > 0.5) then {
                _zone set [2, _anchorPos];
                _zones set [_forEachIndex, _zone];
                _changed = true;
                _markersToRefresh pushBackUnique _zoneId;
            };
        };

        if ((_owner in ["WEST", "EAST", "GUER"]) && {(serverTime - _lastTick) >= _interval}) then {
            private _updatedRows = [];
            private _depositChanged = false;

            {
                private _row = _x;
                private _resourceType = _row param [0, "Resource"];
                private _cycleAmount = 0 max (floor (_row param [1, 0]));
                private _remaining = floor (_row param [2, -1]);
                private _total = floor (_row param [3, -1]);

                if (_total > 0) then {
                    if (_remaining <= 0) then {
                        _updatedRows pushBack [_resourceType, _cycleAmount, 0, _total];
                        continue;
                    };
                    _cycleAmount = _cycleAmount min _remaining;
                };

                private _appliedAmount = [_owner, _resourceType, _cycleAmount] call Waldo_fnc_EcoResource_getAllowedResourceGain;
                if (_appliedAmount > 0) then {
                    [_owner, _resourceType, _appliedAmount, _zone param [1, "Zone"]] call Waldo_fnc_EcoResource_addSideResourceAmount;

                    if (_total > 0) then {
                        _remaining = 0 max (_remaining - _appliedAmount);
                        _depositChanged = true;
                    };
                };

                _updatedRows pushBack [_resourceType, _row param [1, 0], _remaining, _total];
            } forEach ([_zone] call Waldo_fnc_EcoResource_getZoneResourceRows);

            _updatedRows = [_updatedRows] call Waldo_fnc_EcoResource_normalizeZoneResourceRows;
            _zone set [4, _updatedRows];
            _zone set [8, serverTime];
            _zones set [_forEachIndex, _zone];
            _changed = true;

            if (_depositChanged) then {
                _markersToRefresh pushBackUnique _zoneId;
            };

            private _hasInfiniteResource = (_updatedRows findIf {((_x param [3, -1]) <= 0)}) >= 0;
            private _hasFiniteDepositRemaining = (_updatedRows findIf {
                ((_x param [3, -1]) > 0) && {((_x param [2, 0]) > 0)}
            }) >= 0;
            if (!_hasInfiniteResource && {!_hasFiniteDepositRemaining}) then {
                _expiredZoneIds pushBackUnique _zoneId;
            };
        };
    } forEach _zones;

    if (_changed) then {
        [_zones] call Waldo_fnc_EcoResource_setResourceZones;
    };

    {
        [_x, true, "deposit depleted"] call Waldo_fnc_EcoResource_deleteResourceZone;
    } forEach _expiredZoneIds;

    {
        if !(_x in _expiredZoneIds) then {
            [_x] call Waldo_fnc_EcoResource_refreshZoneMarker;
        };
    } forEach _markersToRefresh;

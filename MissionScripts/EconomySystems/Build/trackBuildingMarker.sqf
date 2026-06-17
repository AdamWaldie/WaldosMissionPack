/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - trackBuildingMarker
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_trackBuildingMarker via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_building"];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (isNull _building) exitWith {};

        private _buildName = _building getVariable ["WaldoEcoBuild_BuildDefinitionName", "Building"];
        private _entry = [_buildName] call Waldo_fnc_EcoBuild_getBuildDefinition;
        private _icon = _entry param [5, call Waldo_fnc_EcoResource_getDefaultResourceIcon];
        private _color = _entry param [6, call Waldo_fnc_EcoResource_getDefaultResourceColor];
        private _markerClass = [_icon] call Waldo_fnc_EcoBuild_getBuildMarkerClass;
        private _markerColor = [_color] call Waldo_fnc_EcoResource_getNearestMarkerColor;
        private _markerName = format ["WaldoEcoBuild_Building_%1_%2", diag_tickTime, floor (random 100000)];
        private _markerPos = getPosATL _building;
        private _label = _buildName;
        if (_building getVariable ["WaldoEcoBuild_IsUpgrading", false]) then {
            _label = _label + " (Upgrading)";
        } else {
            if !(_building getVariable ["WaldoEcoBuild_Operational", true]) then {
                _label = _label + " (Disabled)";
            };
        };

        createMarker [_markerName, _markerPos];
        _markerName setMarkerShape "ICON";
        _markerName setMarkerType _markerClass;
        _markerName setMarkerColor _markerColor;
        _markerName setMarkerText _label;
        _markerName setMarkerAlpha (call Waldo_fnc_EcoResource_getResourceMarkerVisibilityAlpha);

        _building setVariable ["WaldoEcoBuild_MarkerName", _markerName, true];

        private _markers = call Waldo_fnc_EcoResource_getActiveResourceMarkers;
        _markers pushBackUnique _markerName;
        missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", _markers, true];

        [_building, _markerName] spawn {
            params ["_building", "_markerName"];

            private _lastPos = getPosATL _building;

            while {!isNull _building} do {
                uiSleep 1;

                if (isNull _building) exitWith {};

                private _currentPos = getPosATL _building;
                if ((_currentPos distance2D _lastPos) > 0.5) then {
                    _markerName setMarkerPos _currentPos;
                    private _detectorAreaMarker = _building getVariable ["WaldoEcoBuild_DetectorAreaMarker", ""];
                    if (_detectorAreaMarker isNotEqualTo "") then {
                        _detectorAreaMarker setMarkerPos _currentPos;
                    };
                    _lastPos = _currentPos;
                };
            };

            if (!isNull _building) then {
                [_building] call Waldo_fnc_EcoBuild_deleteBuildingMarker;
            } else {
                private _markers = call Waldo_fnc_EcoResource_getActiveResourceMarkers;
                private _index = _markers find _markerName;
                if (_index >= 0) then {
                    _markers deleteAt _index;
                    missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", _markers, true];
                };
                deleteMarker _markerName;
            };
        };


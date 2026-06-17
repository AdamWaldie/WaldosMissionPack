/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - refreshBuildingMarker
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_refreshBuildingMarker via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_building", objNull]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (isNull _building) exitWith {};

        private _markerName = _building getVariable ["WaldoEcoBuild_MarkerName", ""];
        if (_markerName isEqualTo "") exitWith {};

        private _buildName = _building getVariable ["WaldoEcoBuild_BuildDefinitionName", "Building"];
        private _entry = [_buildName] call Waldo_fnc_EcoBuild_getBuildDefinition;
        if ((count _entry) <= 0) exitWith {};

        private _icon = _entry param [5, call Waldo_fnc_EcoResource_getDefaultResourceIcon];
        private _color = _entry param [6, call Waldo_fnc_EcoResource_getDefaultResourceColor];
        private _markerClass = [_icon] call Waldo_fnc_EcoBuild_getBuildMarkerClass;
        private _markerColor = [_color] call Waldo_fnc_EcoResource_getNearestMarkerColor;
        private _label = _buildName;
        if (_building getVariable ["WaldoEcoBuild_IsUpgrading", false]) then {
            _label = _label + " (Upgrading)";
        } else {
            if !(_building getVariable ["WaldoEcoBuild_Operational", true]) then {
                _label = _label + " (Disabled)";
            };
        };

        _markerName setMarkerType _markerClass;
        _markerName setMarkerColor _markerColor;
        _markerName setMarkerText _label;


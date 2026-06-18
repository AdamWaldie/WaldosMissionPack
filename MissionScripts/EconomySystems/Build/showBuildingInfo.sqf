/*
 * Author: Waldo
 * Show building info.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_building] call Waldo_fnc_EcoBuild_showBuildingInfo;
 */

        params [["_building", objNull]];

        if (isNull _building) exitWith {};

        private _buildName = _building getVariable ["WaldoEcoBuild_BuildDefinitionName", "Building"];
        private _entry = [_buildName] call Waldo_fnc_EcoBuild_getBuildDefinition;
        if ((count _entry) <= 0) exitWith {};

        private _owner = [_building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"]] call Waldo_fnc_EcoResource_getZoneOwnerLabel;
        private _desc = _entry param [1, ""];
        private _effects = [];
        private _statusLine = "";

        private _produceResource = _entry param [9, ""];
        private _produceAmount = _entry param [10, 0];
        private _produceInterval = _entry param [11, 0];
        private _researchSpeed = _entry param [12, 0];
        private _buildSpeed = _entry param [13, 0];
        private _detectorRange = _entry param [14, 0];
        private _upkeepCosts = _entry param [15, []];
        private _upkeepInterval = _entry param [16, 0];
        private _storageRows = [_entry] call Waldo_fnc_EcoBuild_getBuildStorageRows;
        private _lineBreak = toString [10];

        if (_building getVariable ["WaldoEcoBuild_IsUpgrading", false]) then {
            _statusLine = "Status: UPGRADING" + _lineBreak + format ["Upgrading to %1.", _building getVariable ["WaldoEcoBuild_UpgradeTargetName", ""]];
        } else {
            if !(_building getVariable ["WaldoEcoBuild_Operational", true]) then {
                _statusLine = "Status: DISABLED" + _lineBreak + (_building getVariable ["WaldoEcoBuild_DisabledReason", ""]);
            } else {
                _statusLine = "Status: ACTIVE";
            };
        };

        if (_produceResource isNotEqualTo "" && {_produceAmount > 0} && {_produceInterval > 0}) then {
            _effects pushBack format ["Produces %1 %2 every %3 sec", _produceAmount, _produceResource, _produceInterval];
        };
        if ((count _upkeepCosts) > 0 && {_upkeepInterval > 0}) then {
            _effects pushBack format [
                "Upkeep: %1 every %2 sec",
                (_upkeepCosts apply {format ["%1 %2", _x param [1, 0], _x param [0, ""]]}) joinString ", ",
                _upkeepInterval
            ];
        };
        if ((count _storageRows) > 0) then {
            _effects pushBack format [
                "Storage: %1",
                (_storageRows apply {format ["%1 %2", _x param [1, 0], _x param [0, ""]]}) joinString ", "
            ];
        };
        if (_researchSpeed > 0) then {
            _effects pushBack format ["Research speed +%1%%", _researchSpeed];
        };
        if (_buildSpeed > 0) then {
            _effects pushBack format ["Build speed +%1%%", _buildSpeed];
        };
        if (_detectorRange > 0) then {
            _effects pushBack format ["Detector range %1m", _detectorRange];
        };
        if ((count _effects) <= 0) then {
            _effects pushBack "No active effects";
        };

        hintSilent (
            _buildName + " - Owner: " + _owner
            + (_lineBreak + _lineBreak)
            + _statusLine
            + (_lineBreak + _lineBreak)
            + _desc
            + (_lineBreak + _lineBreak)
            + "Effects:"
            + _lineBreak
            + (_effects joinString _lineBreak)
        );


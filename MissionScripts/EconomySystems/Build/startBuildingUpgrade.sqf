/*
 * Author: Waldo
 * Start building upgrade.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 * 1: _caller <OBJECT> - caller (optional, default: objNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_building, _caller] call Waldo_fnc_EcoBuild_startBuildingUpgrade;
 */

        params [
            ["_building", objNull],
            ["_caller", objNull]
        ];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (isNull _building || isNull _caller) exitWith {};
        if (isNil "Waldo_fnc_EcoResource_getSideKeyFromSide") exitWith {};
        if !([_building, _caller] call Waldo_fnc_EcoBuild_canPlayerViewUpgrade) exitWith {};
        if (_building getVariable ["WaldoEcoBuild_IsUpgrading", false]) exitWith {};
        if (!(isNil "Waldo_fnc_EcoCommand_hasCommandAuthority") && {!([_caller] call Waldo_fnc_EcoCommand_hasCommandAuthority)}) exitWith {};

        private _targetEntry = [_building] call Waldo_fnc_EcoBuild_getUpgradeTargetEntry;
        if ((count _targetEntry) <= 0) exitWith {};

        private _catalog = call Waldo_fnc_EcoBuild_getBuildCatalog;
        if ([_targetEntry, _catalog] call Waldo_fnc_EcoBuild_hasBuildEntryError) exitWith {};

        private _sideKey = _building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"];
        if !([_targetEntry, _sideKey] call Waldo_fnc_EcoBuild_areBuildRequirementsMetForSide) exitWith {};
        if !([_targetEntry, _sideKey] call Waldo_fnc_EcoBuild_canAffordBuildForSide) exitWith {};

        private _upgradeName = _targetEntry param [0, ""];
        {
            [_sideKey, _x param [0, ""], -(_x param [1, 0]), _upgradeName] call Waldo_fnc_EcoResource_addSideResourceAmount;
        } forEach (_targetEntry param [2, []]);

        _building setVariable ["WaldoEcoBuild_IsUpgrading", true, true];
        _building setVariable ["WaldoEcoBuild_UpgradeTargetName", _upgradeName, true];
        _building setVariable ["WaldoEcoBuild_Operational", false, true];
        _building setVariable ["WaldoEcoBuild_DisabledReason", format ["Upgrading to %1.", _upgradeName], true];
        [_building] call Waldo_fnc_EcoBuild_refreshBuildingMarker;

        private _jobId = format [
            "UPG_%1_%2_%3",
            _upgradeName,
            _sideKey,
            floor ((serverTime * 1000) + (random 100000))
        ];
        private _runtimeRows = call Waldo_fnc_EcoBuild_getUpgradeJobRuntime;
        _runtimeRows pushBack [
            _jobId,
            _building,
            _upgradeName,
            _sideKey,
            1 max (_targetEntry param [4, 60]),
            0,
            0,
            serverTime
        ];
        [_runtimeRows] call Waldo_fnc_EcoBuild_setUpgradeJobRuntime;


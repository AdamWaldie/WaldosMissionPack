/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - enableBuilding
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_enableBuilding via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_building", objNull], ["_caller", objNull]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (isNull _building || isNull _caller) exitWith {};
        if !([_building, _caller] call Waldo_fnc_EcoBuild_canPlayerManageBuilding) exitWith {};

        private _buildName = _building getVariable ["WaldoEcoBuild_BuildDefinitionName", ""];
        private _entry = [_buildName] call Waldo_fnc_EcoBuild_getBuildDefinition;
        if ((count _entry) <= 0) exitWith {};

        private _sideKey = _building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"];
        private _upkeepCosts = _entry param [15, []];
        private _canPay = true;

        {
            private _resourceName = _x param [0, ""];
            private _resourceValue = _x param [1, 0];
            if (([_sideKey, _resourceName] call Waldo_fnc_EcoResource_getSideResourceAmount) < _resourceValue) exitWith {
                _canPay = false;
            };
        } forEach _upkeepCosts;
        if !_canPay exitWith {};

        {
            [_sideKey, _x param [0, ""], -(_x param [1, 0]), _buildName] call Waldo_fnc_EcoResource_addSideResourceAmount;
        } forEach _upkeepCosts;

        _building setVariable ["WaldoEcoBuild_ManualDisabled", false, true];
        _building setVariable ["WaldoEcoBuild_Operational", true, true];
        _building setVariable ["WaldoEcoBuild_DisabledReason", "", true];
        _building setVariable ["WaldoEcoBuild_BuildLastUpkeep", serverTime, false];
        _building setVariable ["WaldoEcoBuild_LastDetectionScan", serverTime, false];
        [_building] call Waldo_fnc_EcoBuild_cleanupDetectorVisuals;
        [_building] call Waldo_fnc_EcoBuild_refreshBuildingMarker;


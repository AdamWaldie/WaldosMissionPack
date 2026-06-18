/*
 * Author: Waldo
 * Claim building.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 * 1: _caller <OBJECT> - caller (optional, default: objNull)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_building, _caller] call Waldo_fnc_EcoBuild_claimBuilding;
 */

        params [["_building", objNull], ["_caller", objNull]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (isNull _building || isNull _caller) exitWith {};
        if (isNil "Waldo_fnc_EcoResource_getSideKeyFromSide") exitWith {};

        private _newSide = [side group _caller] call Waldo_fnc_EcoResource_getSideKeyFromSide;
        if !(_newSide in ["WEST", "EAST", "GUER"]) exitWith {};

        private _currentSide = _building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"];
        if (_newSide isEqualTo _currentSide) exitWith {};

        _building setVariable ["WaldoEcoBuild_BuildOwnerSideKey", _newSide, true];
        _building setVariable ["WaldoEcoBuild_BuildLastUpkeep", serverTime, false];
        _building setVariable ["WaldoEcoBuild_BuildLastProduction", serverTime, false];
        _building setVariable ["WaldoEcoBuild_LastDetectionScan", serverTime, false];
        [_building] call Waldo_fnc_EcoBuild_cleanupDetectorVisuals;
        [_building] call Waldo_fnc_EcoBuild_refreshBuildingMarker;


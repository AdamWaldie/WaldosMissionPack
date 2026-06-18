/*
 * Author: Waldo
 * Disable building.
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
 * [_building, _caller] call Waldo_fnc_EcoBuild_disableBuilding;
 */

        params [["_building", objNull], ["_caller", objNull]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (isNull _building || isNull _caller) exitWith {};
        if !([_building, _caller] call Waldo_fnc_EcoBuild_canPlayerManageBuilding) exitWith {};

        _building setVariable ["WaldoEcoBuild_ManualDisabled", true, true];
        _building setVariable ["WaldoEcoBuild_Operational", false, true];
        _building setVariable ["WaldoEcoBuild_DisabledReason", "Building manually disabled.", true];
        _building setVariable ["WaldoEcoBuild_LastDetectionScan", serverTime, false];
        [_building] call Waldo_fnc_EcoBuild_cleanupDetectorVisuals;
        [_building] call Waldo_fnc_EcoBuild_refreshBuildingMarker;


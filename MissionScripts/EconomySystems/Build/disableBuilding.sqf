/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - disableBuilding
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_disableBuilding via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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


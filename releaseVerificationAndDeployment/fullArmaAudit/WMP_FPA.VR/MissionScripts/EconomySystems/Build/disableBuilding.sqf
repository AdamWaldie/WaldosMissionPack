/*
 * Author: WaldoTheWarfighter
 * Manually disable a building that the caller is allowed to manage.
 *
 * Locality / Authority: Economy authority only; operational state is broadcast.
 * Repeat/JIP: Repeating this sets the same disabled state and refreshes
 * detector visuals and marker; joining clients read published object state.
 * Current Callers: EcoBuild_processBuildingManageRequest.
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 * 1: _caller <OBJECT> - caller (optional, default: objNull)
 *
 * Return Value:
 * Nothing.
 * Result: Sets manual-disabled and clears active detection when permitted;
 * invalid objects and unauthorized callers cause no change.
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


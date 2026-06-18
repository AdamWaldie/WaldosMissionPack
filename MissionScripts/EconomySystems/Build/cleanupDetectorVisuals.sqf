/*
 * Author: Waldo
 * Cleanup detector visuals.
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
 * [_building] call Waldo_fnc_EcoBuild_cleanupDetectorVisuals;
 */

        params [["_building", objNull]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (isNull _building) exitWith {};

        [_building] call Waldo_fnc_EcoBuild_cleanupDetectorContactMarkers;

        private _areaMarker = _building getVariable ["WaldoEcoBuild_DetectorAreaMarker", ""];
        if (_areaMarker isNotEqualTo "") then {
            [_areaMarker] call Waldo_fnc_EcoBuild_deleteNamedMarker;
            _building setVariable ["WaldoEcoBuild_DetectorAreaMarker", "", true];
        };


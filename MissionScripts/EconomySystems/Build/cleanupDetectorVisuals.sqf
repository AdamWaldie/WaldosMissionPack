/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - cleanupDetectorVisuals
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_cleanupDetectorVisuals via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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


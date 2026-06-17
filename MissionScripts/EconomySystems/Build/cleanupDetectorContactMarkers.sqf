/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - cleanupDetectorContactMarkers
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_cleanupDetectorContactMarkers via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_building", objNull]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (isNull _building) exitWith {};

        {
            [_x] call Waldo_fnc_EcoBuild_deleteNamedMarker;
        } forEach (_building getVariable ["WaldoEcoBuild_DetectorContactMarkers", []]);

        _building setVariable ["WaldoEcoBuild_DetectorContactMarkers", [], true];


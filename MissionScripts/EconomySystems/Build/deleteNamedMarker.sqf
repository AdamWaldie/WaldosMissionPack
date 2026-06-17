/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - deleteNamedMarker
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_deleteNamedMarker via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_markerName", ""]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (_markerName isEqualTo "") exitWith {};

        [_markerName] call Waldo_fnc_EcoBuild_removeSharedMarkerName;
        deleteMarker _markerName;


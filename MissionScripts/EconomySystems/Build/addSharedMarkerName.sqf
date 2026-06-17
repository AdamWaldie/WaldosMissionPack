/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - addSharedMarkerName
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_addSharedMarkerName via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_markerName", ""]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (_markerName isEqualTo "") exitWith {};

        _markerName setMarkerAlpha (call Waldo_fnc_EcoResource_getResourceMarkerVisibilityAlpha);

        private _markers = call Waldo_fnc_EcoResource_getActiveResourceMarkers;
        _markers pushBackUnique _markerName;
        missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", _markers, true];


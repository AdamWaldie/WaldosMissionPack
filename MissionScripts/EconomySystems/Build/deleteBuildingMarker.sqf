/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - deleteBuildingMarker
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_deleteBuildingMarker via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_building"];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (isNull _building) exitWith {};

        private _markerName = _building getVariable ["WaldoEcoBuild_MarkerName", ""];
        if (_markerName isEqualTo "") exitWith {};

        private _markers = call Waldo_fnc_EcoResource_getActiveResourceMarkers;
        private _index = _markers find _markerName;
        if (_index >= 0) then {
            _markers deleteAt _index;
            missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", _markers, true];
        };

        deleteMarker _markerName;
        _building setVariable ["WaldoEcoBuild_MarkerName", nil, true];


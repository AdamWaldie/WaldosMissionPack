/*
 * Author: Waldo
 * Delete building marker.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _building <ANY> - building
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_building] call Waldo_fnc_EcoBuild_deleteBuildingMarker;
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


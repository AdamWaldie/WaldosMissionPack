/*
 * Author: WaldoTheWarfighter
 * Deletes a building's map marker and clears its published marker-name tag.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _building <OBJECT> - registered building
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_building] call Waldo_fnc_EcoBuild_deleteBuildingMarker;
 * Locality/Authority: Economy authority only; removes a global marker.
 * Repeat/JIP Behaviour: Repeat deletion is harmless; cleared tag reaches JIP.
 * Current Callers: Building deletion, disable and marker maintenance.
 * Result: The building no longer has a WMP marker.
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


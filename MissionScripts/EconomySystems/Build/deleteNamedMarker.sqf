/*
 * Author: Waldo
 * Delete named marker.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _markerName <STRING> - marker name (optional, default: "")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_markerName] call Waldo_fnc_EcoBuild_deleteNamedMarker;
 */

        params [["_markerName", ""]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (_markerName isEqualTo "") exitWith {};

        [_markerName] call Waldo_fnc_EcoBuild_removeSharedMarkerName;
        deleteMarker _markerName;


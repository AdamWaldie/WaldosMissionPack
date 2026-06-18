/*
 * Author: Waldo
 * Add shared marker name.
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
 * [_markerName] call Waldo_fnc_EcoBuild_addSharedMarkerName;
 */

        params [["_markerName", ""]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (_markerName isEqualTo "") exitWith {};

        _markerName setMarkerAlpha (call Waldo_fnc_EcoResource_getResourceMarkerVisibilityAlpha);

        private _markers = call Waldo_fnc_EcoResource_getActiveResourceMarkers;
        _markers pushBackUnique _markerName;
        missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", _markers, true];


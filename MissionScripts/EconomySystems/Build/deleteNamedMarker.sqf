/*
 * Author: WaldoTheWarfighter
 * Deletes an Economy marker by name and removes it from the shared registry.
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
 * Locality/Authority: Economy authority only; deletes a global marker.
 * Repeat/JIP Behaviour: Repeat deletion of an absent name is harmless; JIP gets updated registry.
 * Current Callers: Detector contact and building marker cleanup.
 * Result: Marker name is no longer tracked or visible.
 */

        params [["_markerName", ""]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (_markerName isEqualTo "") exitWith {};

        [_markerName] call Waldo_fnc_EcoBuild_removeSharedMarkerName;
        deleteMarker _markerName;


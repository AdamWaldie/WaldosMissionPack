/*
 * Author: WaldoTheWarfighter
 * Removes a marker name from the published Economy cleanup registry.
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
 * [_markerName] call Waldo_fnc_EcoBuild_removeSharedMarkerName;
 * Locality/Authority: Economy authority only; changes public registry.
 * Repeat/JIP Behaviour: Missing names are ignored; JIP receives current list.
 * Current Callers: Named marker deletion and building marker cleanup.
 * Result: Future cleanup no longer targets the removed marker.
 */

        params [["_markerName", ""]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (_markerName isEqualTo "") exitWith {};

        private _markers = call Waldo_fnc_EcoResource_getActiveResourceMarkers;
        private _index = _markers find _markerName;
        if (_index >= 0) then {
            _markers deleteAt _index;
            missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", _markers, true];
        };


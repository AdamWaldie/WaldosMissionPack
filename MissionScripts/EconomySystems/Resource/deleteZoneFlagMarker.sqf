/*
 * Author: Waldo
 * Delete zone flag marker.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _zoneId <ANY> - zone id
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_zoneId] call Waldo_fnc_EcoResource_deleteZoneFlagMarker;
 */

    params ["_zoneId"];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _index = [_zoneId] call Waldo_fnc_EcoResource_findResourceZoneIndex;
    if (_index < 0) exitWith {};

    private _zones = call Waldo_fnc_EcoResource_getResourceZones;
    private _zone = _zones select _index;
    private _markerName = _zone param [12, ""];
    if !(_markerName isEqualType "") then {
        _markerName = "";
    };

    if (_markerName isNotEqualTo "") then {
        private _activeMarkers = call Waldo_fnc_EcoResource_getActiveResourceMarkers;
        while {(_activeMarkers find _markerName) >= 0} do {
            _activeMarkers deleteAt (_activeMarkers find _markerName);
        };
        missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", _activeMarkers, true];
        deleteMarker _markerName;
    };

    _zone set [12, ""];
    _zones set [_index, _zone];
    [_zones] call Waldo_fnc_EcoResource_setResourceZones;

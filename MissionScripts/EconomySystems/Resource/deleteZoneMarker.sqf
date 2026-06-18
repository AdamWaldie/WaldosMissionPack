/*
 * Author: Waldo
 * Delete zone marker.
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
 * [_zoneId] call Waldo_fnc_EcoResource_deleteZoneMarker;
 */

    params ["_zoneId"];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _index = [_zoneId] call Waldo_fnc_EcoResource_findResourceZoneIndex;
    if (_index < 0) exitWith {};

    private _zones = call Waldo_fnc_EcoResource_getResourceZones;
    private _zone = _zones select _index;
    private _markerName = _zone param [9, ""];

    if (_markerName isNotEqualTo "") then {
        private _markers = call Waldo_fnc_EcoResource_getActiveResourceMarkers;
        while {(_markers find _markerName) >= 0} do {
            _markers deleteAt (_markers find _markerName);
        };
        missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", _markers, true];
        deleteMarker _markerName;
    };

    [_zoneId] call Waldo_fnc_EcoResource_deleteZoneDetailMarkers;
    [_zoneId] call Waldo_fnc_EcoResource_deleteZoneFlagMarker;

    _zones = call Waldo_fnc_EcoResource_getResourceZones;
    _index = [_zoneId] call Waldo_fnc_EcoResource_findResourceZoneIndex;
    if (_index < 0) exitWith {};
    _zone = _zones select _index;

    _zone set [9, ""];
    _zones set [_index, _zone];
    [_zones] call Waldo_fnc_EcoResource_setResourceZones;

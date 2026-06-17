/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - createZoneMarker
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_createZoneMarker via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_zoneId"];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _index = [_zoneId] call Waldo_fnc_EcoResource_findResourceZoneIndex;
    if (_index < 0) exitWith {};

    private _zones = call Waldo_fnc_EcoResource_getResourceZones;
    private _zone = _zones select _index;
    private _markerName = format ["WaldoEcoResource_Zone_%1", _zoneId];

    createMarker [_markerName, _zone param [2, [0, 0, 0]]];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "Border";
    _markerName setMarkerAlpha (call Waldo_fnc_EcoResource_getResourceMarkerVisibilityAlpha);

    _zone set [9, _markerName];
    _zones set [_index, _zone];
    [_zones] call Waldo_fnc_EcoResource_setResourceZones;

    private _markers = call Waldo_fnc_EcoResource_getActiveResourceMarkers;
    _markers pushBackUnique _markerName;
    missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", _markers, true];

    [_zoneId] call Waldo_fnc_EcoResource_refreshZoneMarker;

/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - refreshZoneMarker
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_refreshZoneMarker via WaldosFunctions.sqf.
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
    private _markerName = _zone param [9, ""];
    if (_markerName isEqualTo "") exitWith {};

    private _resourceRows = [_zone] call Waldo_fnc_EcoResource_getZoneResourceRows;
    private _resourceType = [_resourceRows] call Waldo_fnc_EcoResource_getPrimaryResourceType;
    private _resourceDef = [_resourceType] call Waldo_fnc_EcoResource_getResourceDefinition;
    private _color = [(_resourceDef param [1, "#FFFFFF"])] call Waldo_fnc_EcoResource_getNearestMarkerColor;
    private _owner = [_zone param [5, "NONE"]] call Waldo_fnc_EcoResource_getZoneOwnerLabel;

    _markerName setMarkerPos (_zone param [2, [0, 0, 0]]);
    _markerName setMarkerSize [(_zone param [3, 25]), (_zone param [3, 25])];
    _markerName setMarkerColor _color;
    _markerName setMarkerText format ["%1 (%2)", _zone param [1, "Zone"], _owner];

    [_zoneId] call Waldo_fnc_EcoResource_refreshZoneFlagMarker;
    [_zoneId] call Waldo_fnc_EcoResource_refreshZoneDetailMarkers;

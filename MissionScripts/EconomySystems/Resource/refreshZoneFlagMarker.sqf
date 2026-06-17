/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - refreshZoneFlagMarker
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_refreshZoneFlagMarker via WaldosFunctions.sqf.
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
    private _owner = _zone param [5, "NONE"];
    private _markerClass = [_owner] call Waldo_fnc_EcoResource_getZoneOwnerFlagMarkerClass;

    if (_markerClass isEqualTo "") exitWith {
        [_zoneId] call Waldo_fnc_EcoResource_deleteZoneFlagMarker;
    };

    private _markerName = _zone param [12, ""];
    if !(_markerName isEqualType "") then {
        _markerName = "";
    };

    private _markerPos = +(_zone param [2, [0, 0, 0]]);
    while {(count _markerPos) < 3} do {
        _markerPos pushBack 0;
    };
    _markerPos set [1, (_markerPos param [1, 0]) + 18];

    if (_markerName isEqualTo "" || {(markerType _markerName) isEqualTo ""}) then {
        _markerName = format ["WaldoEcoResource_ZoneFlag_%1_%2", _zoneId, floor (random 100000)];
        createMarker [_markerName, _markerPos];
        _markerName setMarkerShape "ICON";
    } else {
        _markerName setMarkerPos _markerPos;
    };

    private _visible = missionNamespace getVariable ["WaldoEcoResource_ResourceMarkersVisible", true];
    private _alpha = [0, 1] select _visible;

    _markerName setMarkerType _markerClass;
    _markerName setMarkerColor "ColorWhite";
    _markerName setMarkerAlpha _alpha;
    _markerName setMarkerText "";

    private _activeMarkers = call Waldo_fnc_EcoResource_getActiveResourceMarkers;
    _activeMarkers pushBackUnique _markerName;
    missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", _activeMarkers, true];

    _zone set [12, _markerName];
    _zones set [_index, _zone];
    [_zones] call Waldo_fnc_EcoResource_setResourceZones;

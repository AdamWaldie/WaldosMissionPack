/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - deleteZoneDetailMarkers
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_deleteZoneDetailMarkers via WaldosFunctions.sqf.
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
    private _detailMarkers = _zone param [11, []];
    if !(_detailMarkers isEqualType []) then {
        _detailMarkers = [];
    };

    private _activeMarkers = call Waldo_fnc_EcoResource_getActiveResourceMarkers;
    {
        private _markerName = _x;
        if !(_markerName isEqualType "") then {continue;};
        if (_markerName isEqualTo "") then {continue;};

        while {(_activeMarkers find _markerName) >= 0} do {
            _activeMarkers deleteAt (_activeMarkers find _markerName);
        };
        deleteMarker _markerName;
    } forEach _detailMarkers;

    missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", _activeMarkers, true];
    _zone set [11, []];
    _zones set [_index, _zone];
    [_zones] call Waldo_fnc_EcoResource_setResourceZones;

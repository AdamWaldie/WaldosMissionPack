/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - refreshZoneDetailMarkers
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_refreshZoneDetailMarkers via WaldosFunctions.sqf.
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
    private _resourceRows = [_zone] call Waldo_fnc_EcoResource_getZoneResourceRows;
    if ((count _resourceRows) <= 0) exitWith {
        [_zoneId] call Waldo_fnc_EcoResource_deleteZoneDetailMarkers;
    };

    private _basePos = +(_zone param [2, [0, 0, 0]]);
    while {(count _basePos) < 3} do {
        _basePos pushBack 0;
    };

    private _existingMarkers = _zone param [11, []];
    if !(_existingMarkers isEqualType []) then {
        _existingMarkers = [];
    };

    private _visible = missionNamespace getVariable ["WaldoEcoResource_ResourceMarkersVisible", true];
    private _alpha = [0, 1] select _visible;
    private _activeMarkers = call Waldo_fnc_EcoResource_getActiveResourceMarkers;
    private _updatedMarkers = [];

    {
        private _row = _x;
        private _resourceType = _row param [0, "Resource"];
        private _markerName = _existingMarkers param [_forEachIndex, ""];
        private _markerPos = +_basePos;
        _markerPos set [1, (_markerPos param [1, 0]) - (_forEachIndex * 18)];

        if (_markerName isEqualTo "" || {(markerType _markerName) isEqualTo ""}) then {
            _markerName = format ["WaldoEcoResource_ZoneRes_%1_%2_%3", _zoneId, _forEachIndex, floor (random 100000)];
            createMarker [_markerName, _markerPos];
            _markerName setMarkerShape "ICON";
        } else {
            _markerName setMarkerPos _markerPos;
        };

        private _resourceDef = [_resourceType] call Waldo_fnc_EcoResource_getResourceDefinition;
        private _markerClass = [_resourceType] call Waldo_fnc_EcoResource_getResourceMarkerClass;
        private _markerColor = [(_resourceDef param [1, "#FFFFFF"])] call Waldo_fnc_EcoResource_getNearestMarkerColor;

        _markerName setMarkerType _markerClass;
        _markerName setMarkerColor _markerColor;
        _markerName setMarkerAlpha _alpha;
        _markerName setMarkerText ([_row] call Waldo_fnc_EcoResource_getZoneResourceMarkerText);

        _activeMarkers pushBackUnique _markerName;
        _updatedMarkers pushBack _markerName;
    } forEach _resourceRows;

    for "_i" from (count _resourceRows) to ((count _existingMarkers) - 1) do {
        private _markerName = _existingMarkers param [_i, ""];
        if (_markerName isEqualTo "") then {continue;};

        while {(_activeMarkers find _markerName) >= 0} do {
            _activeMarkers deleteAt (_activeMarkers find _markerName);
        };
        deleteMarker _markerName;
    };

    missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", _activeMarkers, true];
    _zone set [11, _updatedMarkers];
    _zones set [_index, _zone];
    [_zones] call Waldo_fnc_EcoResource_setResourceZones;

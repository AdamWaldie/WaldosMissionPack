/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - trackCrateMarker
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_trackCrateMarker via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_crate"];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
    if (isNull _crate) exitWith {};

    private _resourceRows = [_crate] call Waldo_fnc_EcoResource_getCrateResourceRows;
    private _resourceType = [_resourceRows] call Waldo_fnc_EcoResource_getPrimaryResourceType;
    private _markerName = format ["WaldoEcoResource_Crate_%1_%2", diag_tickTime, floor (random 100000)];
    private _markerPos = getPosATL _crate;
    private _resourceDef = [_resourceType] call Waldo_fnc_EcoResource_getResourceDefinition;
    private _markerClass = [_resourceType] call Waldo_fnc_EcoResource_getResourceMarkerClass;
    private _markerColor = [(_resourceDef param [1, "#FFFFFF"])] call Waldo_fnc_EcoResource_getNearestMarkerColor;

    createMarker [_markerName, _markerPos];
    _markerName setMarkerShape "ICON";
    _markerName setMarkerType _markerClass;
    _markerName setMarkerColor _markerColor;
    _markerName setMarkerText ([_resourceRows] call Waldo_fnc_EcoResource_getResourceRowsSummaryText);
    _markerName setMarkerAlpha (call Waldo_fnc_EcoResource_getResourceMarkerVisibilityAlpha);

    _crate setVariable ["WaldoEcoResource_MarkerName", _markerName, true];

    private _markers = call Waldo_fnc_EcoResource_getActiveResourceMarkers;
    _markers pushBackUnique _markerName;
    missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", _markers, true];

    [_crate, _markerName] spawn {
        params ["_crate", "_markerName"];

        private _lastPos = getPosATL _crate;

        while {alive _crate && {!isNull _crate} && {_crate getVariable ["WaldoEcoResource_Collected", false] isEqualTo false}} do {
            uiSleep 1;

            if (isNull _crate) exitWith {};

            private _currentPos = getPosATL _crate;
            if ((_currentPos distance2D _lastPos) > 0.5) then {
                _markerName setMarkerPos _currentPos;
                _lastPos = _currentPos;
            };
        };

        if (!isNull _crate) then {
            [_crate] call Waldo_fnc_EcoResource_deleteCrateMarker;
        } else {
            deleteMarker _markerName;
        };
    };

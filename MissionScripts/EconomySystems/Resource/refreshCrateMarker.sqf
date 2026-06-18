/*
 * Author: Waldo
 * Refresh crate marker.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _crate <OBJECT> - crate (optional, default: objNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_crate] call Waldo_fnc_EcoResource_refreshCrateMarker;
 */

    params [["_crate", objNull]];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
    if (isNull _crate) exitWith {};

    private _markerName = _crate getVariable ["WaldoEcoResource_MarkerName", ""];
    if (_markerName isEqualTo "") exitWith {};

    private _resourceRows = [_crate] call Waldo_fnc_EcoResource_getCrateResourceRows;
    if ((count _resourceRows) <= 0) exitWith {
        [_crate] call Waldo_fnc_EcoResource_deleteCrateMarker;
    };

    private _resourceType = [_resourceRows] call Waldo_fnc_EcoResource_getPrimaryResourceType;
    private _resourceDef = [_resourceType] call Waldo_fnc_EcoResource_getResourceDefinition;
    private _markerClass = [_resourceType] call Waldo_fnc_EcoResource_getResourceMarkerClass;
    private _markerColor = [(_resourceDef param [1, "#FFFFFF"])] call Waldo_fnc_EcoResource_getNearestMarkerColor;

    _markerName setMarkerPos (getPosATL _crate);
    _markerName setMarkerType _markerClass;
    _markerName setMarkerColor _markerColor;
    _markerName setMarkerText ([_resourceRows] call Waldo_fnc_EcoResource_getResourceRowsSummaryText);

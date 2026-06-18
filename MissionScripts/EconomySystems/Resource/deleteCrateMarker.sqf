/*
 * Author: Waldo
 * Delete crate marker.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _crate <ANY> - crate
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_crate] call Waldo_fnc_EcoResource_deleteCrateMarker;
 */

    params ["_crate"];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
    if (isNull _crate) exitWith {};

    private _markerName = _crate getVariable ["WaldoEcoResource_MarkerName", ""];
    if (_markerName isEqualTo "") exitWith {};

    private _markers = call Waldo_fnc_EcoResource_getActiveResourceMarkers;
    private _index = _markers find _markerName;
    if (_index >= 0) then {
        _markers deleteAt _index;
        missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", _markers, true];
    };

    deleteMarker _markerName;
    _crate setVariable ["WaldoEcoResource_MarkerName", nil, true];

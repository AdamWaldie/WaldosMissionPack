/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - deleteCrateMarker
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_deleteCrateMarker via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

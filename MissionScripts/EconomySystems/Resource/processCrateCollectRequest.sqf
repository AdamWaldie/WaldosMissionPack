/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - processCrateCollectRequest
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_processCrateCollectRequest via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_crate", objNull], ["_request", []]];

    if (isNull _crate) exitWith {};
    if !(_request isEqualType []) exitWith {};
    if ((count _request) < 4) exitWith {};

    private _requestId = _request param [3, ""];
    if (_requestId isEqualTo "") exitWith {};

    private _handled = missionNamespace getVariable ["WaldoEcoResource_CollectRequestsHandled", []];
    if !(_handled isEqualType []) then {_handled = [];};
    if (_requestId in _handled) exitWith {};

    _handled pushBack _requestId;
    while {(count _handled) > 64} do {
        _handled deleteAt 0;
    };
    missionNamespace setVariable ["WaldoEcoResource_CollectRequestsHandled", _handled];

    _crate setVariable ["WaldoEcoResource_CollectRequest", [], true];

    private _caller = objectFromNetId (_request param [0, ""]);
    if (isNull _caller) exitWith {};
    if (!alive _caller) exitWith {};
    if ((_caller distance _crate) > 8) exitWith {};

    [_crate, _caller] call Waldo_fnc_EcoResource_collectCrate;

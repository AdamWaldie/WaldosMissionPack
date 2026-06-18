/*
 * Author: Waldo
 * Process crate collect request.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _crate <OBJECT> - crate (optional, default: objNull)
 * 1: _request <ARRAY> - request (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_crate, _request] call Waldo_fnc_EcoResource_processCrateCollectRequest;
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

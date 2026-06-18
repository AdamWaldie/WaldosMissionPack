/*
 * Author: Waldo
 * Process zone capture request.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _unit <OBJECT> - unit (optional, default: objNull)
 * 1: _request <ARRAY> - request (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_unit, _request] call Waldo_fnc_EcoResource_processZoneCaptureRequest;
 */

    params [["_unit", objNull], ["_request", []]];

    if (isNull _unit) exitWith {};
    if !(_request isEqualType []) exitWith {};
    if ((count _request) < 6) exitWith {};

    private _requestId = _request param [5, ""];
    if (_requestId isEqualTo "") exitWith {};

    private _handled = missionNamespace getVariable ["WaldoEcoResource_ZoneCaptureRequestsHandled", []];
    if !(_handled isEqualType []) then {_handled = [];};
    if (_requestId in _handled) exitWith {};

    _handled pushBack _requestId;
    while {(count _handled) > 64} do {
        _handled deleteAt 0;
    };
    missionNamespace setVariable ["WaldoEcoResource_ZoneCaptureRequestsHandled", _handled];

    _unit setVariable ["WaldoEcoResource_ZoneCaptureRequest", [], true];

    private _zoneId = _request param [0, ""];
    private _sideKey = _request param [1, "NONE"];
    private _capturePos = _request param [2, []];
    private _actorName = _request param [4, ""];

    [_zoneId, _sideKey, _capturePos, _actorName] call Waldo_fnc_EcoResource_captureResourceZoneForSideKey;

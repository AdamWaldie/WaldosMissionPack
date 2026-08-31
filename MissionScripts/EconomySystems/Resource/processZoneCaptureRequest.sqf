/*
 * Author: WaldoTheWarfighter
 * Process zone capture request.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 * Locality / Authority: Server authority only; preserves existing actor, side, range and registered-zone
 * validation before changing capture state.
 * Repeat / JIP Behaviour: Existing bounded request-token history rejects duplicate captures. Requests
 * are transient and not part of JIP state.
 *
 * Arguments:
 * 0: _unit <OBJECT> - unit (optional, default: objNull)
 * 1: _request <ARRAY> - request (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Current Callers: Waldo_fnc_EcoCore_submitRequestServer and the documented legacy processor API.
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

    if !((_unit getVariable ["WaldoEcoResource_ZoneCaptureRequest", []]) isEqualTo []) then {
        _unit setVariable ["WaldoEcoResource_ZoneCaptureRequest", [], true];
    };

    private _zoneId = _request param [0, ""];
    private _sideKey = _request param [1, "NONE"];
    private _capturePos = _request param [2, []];
    private _actorName = _request param [4, ""];

    [_zoneId, _sideKey, _capturePos, _actorName] call Waldo_fnc_EcoResource_captureResourceZoneForSideKey;

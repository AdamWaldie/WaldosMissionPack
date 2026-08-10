/*
 * Author: WaldoTheWarfighter, Val
 * Starts the automatic return-to-base leg after a destination worker has confirmed that the
 * transport is settled and contains no human occupant in any driver, commander, turret, FFV or
 * cargo seat. This wrapper makes RTB acceptance observable instead of fire-and-forget.
 *
 * Locality, authority, repeat and JIP behaviour:
 * Server only. Calls must be server-local or originate from server owner 2. The completed request
 * ID and DISEMBARKING state are checked again immediately before issuing RTB, so a late worker cannot
 * replace a newer destination or manual order. Waldo_fnc_TransportRequestServer performs the actual
 * atomic state/marker/dispatch transition and publishes the result for current and JIP clients.
 *
 * Arguments:
 * 0: service ID <STRING> - registered transport key.
 * 1: completed destination request ID <NUMBER> - request that became empty and settled.
 *
 * Return Value:
 * <BOOL> - true only when TransportRequestServer accepted and dispatched the RTB leg.
 *
 * Current caller:
 * Waldo_fnc_TransportReportServer through a server-to-server remoteExecCall.
 *
 * Example:
 * ["RAVEN_1", 12] remoteExecCall ["Waldo_fnc_TransportAutoRtbServer", 2];
 */

params [
    ["_id", "", [""]],
    ["_requestId", -1, [0]]
];
if (!isServer || {_id == ""} || {_requestId < 0}) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {
    diag_log format ["[WMP TRANSPORT] Automatic RTB rejected before lookup: service=%1 request=%2 remoteOwner=%3.", _id, _requestId, remoteExecutedOwner];
    false
};

private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
private _entry = _services getOrDefault [_id, createHashMap];
if (
    _entry isEqualTo createHashMap
    || {_entry getOrDefault ["requestId", -1] != _requestId}
    || {_entry getOrDefault ["state", ""] != "DISEMBARKING"}
) exitWith {
    diag_log format ["[WMP TRANSPORT] Automatic RTB cancelled as stale: service=%1 request=%2.", _id, _requestId];
    false
};

private _vehicle = _entry getOrDefault ["vehicle", objNull];
if (isNull _vehicle || {!alive _vehicle} || {isNull driver _vehicle} || {!alive driver _vehicle}) exitWith {
    diag_log format ["[WMP TRANSPORT] Automatic RTB rejected for unusable vehicle: service=%1 request=%2.", _id, _requestId];
    false
};

private _requester = _entry getOrDefault ["requester", objNull];
private _accepted = ["RTB", _entry get "type", _vehicle, [], _requester] call Waldo_fnc_TransportRequestServer;
diag_log format [
    "[WMP TRANSPORT] Automatic RTB result: service=%1 completedRequest=%2 accepted=%3 nextState=%4 nextRequest=%5 remoteOwner=%6.",
    _id, _requestId, _accepted,
    _vehicle getVariable ["Waldo_TransportService_State", "UNKNOWN"],
    _vehicle getVariable ["Waldo_TransportService_RequestId", -1],
    remoteExecutedOwner
];
_accepted

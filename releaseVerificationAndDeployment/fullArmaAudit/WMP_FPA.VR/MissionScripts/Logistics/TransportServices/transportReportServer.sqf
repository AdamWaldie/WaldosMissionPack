/*
 * Author: WaldoTheWarfighter, Val
 * Accepts arrival/failure reports from the AI locality owner and advances the authoritative state
 * only when service ID, request ID and phase still match. Pickup arrivals wait for a destination;
 * destination arrivals wait for disembarkation; RTB arrivals restore availability. Failed physical
 * RTB may use the explicitly configured empty-vehicle fail-safe reset.
 *
 * Arguments: 0 service ID; 1 request ID; 2 phase; 3 result (ARRIVED or FAILED).
 * Return Value: Boolean - true when the current request was advanced.
 * Example: ["RAVEN_1",12,"PICKUP","ARRIVED"] remoteExecCall ["Waldo_fnc_TransportReportServer",2];
 * Current caller: Waldo_fnc_TransportDispatchLocal.
 */
params ["_id", "_requestId", "_phase", "_result"];
if (!isServer) exitWith {false};
private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
private _entry = _services getOrDefault [_id, createHashMap];
if (_entry isEqualTo createHashMap || {_entry getOrDefault ["requestId", -1] != _requestId}) exitWith {false};
private _vehicle = _entry getOrDefault ["vehicle", objNull];
if (isNull _vehicle) exitWith {false};
private _expectedOwner = if (isNull driver _vehicle) then {-1} else {groupOwner group driver _vehicle};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != _expectedOwner}) exitWith {false};
private _type = _entry get "type";
private _requester = _entry getOrDefault ["requester", objNull];
private _config = _entry get "config";
private _notifyTransportAudience = {
    params ["_message", "_severity"];
    private _recipients = (crew _vehicle) select {isPlayer _x};
    if (!isNull _requester && {isPlayer _requester}) then {_recipients pushBackUnique _requester};
    {[_type, _message, _severity, _id] remoteExecCall ["Waldo_fnc_TransportNotifyLocal", owner _x]} forEach _recipients;
};
_phase = toUpperANSI _phase;
_result = toUpperANSI _result;
diag_log format ["[WMP TRANSPORT] Report service=%1 request=%2 phase=%3 result=%4 state=%5", _id, _requestId, _phase, _result, _entry getOrDefault ["state", "UNKNOWN"]];
private _destinationMarker = _entry getOrDefault ["destinationMarker", ""];
if (_destinationMarker != "") then {deleteMarker _destinationMarker; _entry deleteAt "destinationMarker"};

if (_result == "FAILED") exitWith {
    private _landingPad = _entry getOrDefault ["landingPad", objNull];
    if (!isNull _landingPad) then {deleteVehicle _landingPad};
    _entry deleteAt "landingPad";
    [format ["%1 is stuck and could not complete its %2 route. Clear the obstruction, then use Select / Manage Transport > %1 > Retry Current Route or order RTB.", _entry get "name", toLowerANSI _phase], "ERROR"] call _notifyTransportAudience;
    if (_phase == "RTB" && {_config getOrDefault ["failSafeReset", false]} && {(crew _vehicle findIf {isPlayer _x}) < 0}) then {
        _vehicle setVehiclePosition [_entry get "startPos", [], 0, "NONE"];
        _vehicle setDir (_entry get "startDir");
        _vehicle setVelocity [0, 0, 0];
        [_id, _requestId, "RTB", "ARRIVED"] call Waldo_fnc_TransportReportServer;
    } else {
        _entry set ["state", "STUCK"];
        _entry set ["lastFailedPhase", _phase];
        _vehicle setVariable ["Waldo_TransportService_State", "STUCK", true];
        _services set [_id, _entry];
        missionNamespace setVariable ["Waldo_Transport_Services", _services];
    };
    true
};

switch (_phase) do {
    case "PICKUP": {
        private _group = group driver _vehicle;
        _entry set ["state", "BOARDING"];
        _vehicle setVariable ["Waldo_TransportService_State", "BOARDING", true];
        [_group, getPosATL _vehicle, _vehicle, _requestId, _config getOrDefault ["keepEngineOnAway", true]] remoteExecCall ["Waldo_fnc_TransportStopGroupLocal", groupOwner _group];
        if (!isNull _requester) then {[_type, format ["%1 is ready for boarding. Enter the transport and select a destination through WMP Transport.", _entry get "name"], "SUCCESS", _id] remoteExecCall ["Waldo_fnc_TransportNotifyLocal", owner _requester]};
        [_id, _requestId, _config getOrDefault ["boardingSeconds", 300]] spawn {
            params ["_id", "_requestId", "_seconds"];
            private _deadline = serverTime + (_seconds max 15);
            // keepEngineOnAway's touchdown assertion in Waldo_fnc_TransportDispatchLocal only covers the
            // instant of landing - the boarding wait itself can run for the whole configured window
            // (default 300s), long enough for vanilla Arma's own idle-engine management to switch a
            // stationary helicopter back off mid-wait. Poll and re-assert for the duration instead of once.
            waitUntil {
                sleep 5;
                private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
                private _entry = _services getOrDefault [_id, createHashMap];
                if (_entry isEqualTo createHashMap || {_entry getOrDefault ["requestId", -1] != _requestId} || {_entry getOrDefault ["state", ""] != "BOARDING"}) exitWith {true};
                private _vehicle = _entry get "vehicle";
                private _config = _entry get "config";
                if (alive _vehicle && {_vehicle isKindOf "Helicopter"} && {_config getOrDefault ["keepEngineOnAway", true]}) then {
                    _vehicle engineOn true;
                };
                serverTime >= _deadline
            };
            private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
            private _entry = _services getOrDefault [_id, createHashMap];
            if !(_entry isEqualTo createHashMap) then {
                if (_entry getOrDefault ["requestId", -1] == _requestId && {_entry getOrDefault ["state", ""] == "BOARDING"}) then {
                    ["RTB", _entry get "type", _entry get "vehicle", [], _entry getOrDefault ["requester", objNull]] call Waldo_fnc_TransportRequestServer;
                };
            };
        };
    };
    case "DESTINATION": {
        private _group = group driver _vehicle;
        _entry set ["state", "DISEMBARKING"];
        _vehicle setVariable ["Waldo_TransportService_State", "DISEMBARKING", true];
        [_group, getPosATL _vehicle, _vehicle, _requestId, _config getOrDefault ["keepEngineOnAway", true]] remoteExecCall ["Waldo_fnc_TransportStopGroupLocal", groupOwner _group];
        [format ["%1 reached the destination. Dismount when ready.", _entry get "name"], "SUCCESS"] call _notifyTransportAudience;
        [_id, _requestId] spawn {
            params ["_id", "_requestId"];
            private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
            private _entry = _services getOrDefault [_id, createHashMap];
            if (_entry isEqualTo createHashMap) exitWith {};
            private _vehicle = _entry get "vehicle";
            private _config = _entry get "config";
            private _deadline = serverTime + (_config getOrDefault ["destinationDwell", 45]);
            private _keepEngineOn = _vehicle isKindOf "Helicopter" && {_config getOrDefault ["keepEngineOnAway", true]};
            private _lastEngineAssert = 0;
            waitUntil {
                sleep 1;
                // Same idle-down risk as the boarding wait: the destination dwell can also run for its
                // whole configured window, so re-assert periodically rather than relying on the one-shot
                // touchdown assertion alone.
                if (_keepEngineOn && {alive _vehicle} && {serverTime - _lastEngineAssert >= 5}) then {
                    _vehicle engineOn true;
                    _lastEngineAssert = serverTime;
                };
                private _baseCrew = _entry getOrDefault ["baseCrew", []];
                (crew _vehicle findIf {!(_x in _baseCrew)}) < 0 || {serverTime >= _deadline} || {!alive _vehicle}
            };
            if (_config getOrDefault ["forceDisembark", false]) then {
                private _baseCrew = _entry getOrDefault ["baseCrew", []];
                {if !(_x in _baseCrew) then {[_x] remoteExecCall ["moveOut", owner _x]}} forEach crew _vehicle;
            };
            private _requester = _entry getOrDefault ["requester", objNull];
            if (isNull _requester) then {
                ["RTB", _entry get "type", _vehicle, [], objNull] call Waldo_fnc_TransportRequestServer;
            } else {
                ["RTB", _entry get "type", _vehicle, [], _requester] call Waldo_fnc_TransportRequestServer;
            };
        };
    };
    case "RTB": {
        private _landingPad = _entry getOrDefault ["landingPad", objNull];
        if (!isNull _landingPad) then {deleteVehicle _landingPad};
        _entry deleteAt "landingPad";
        _entry set ["state", "AVAILABLE"];
        _entry set ["requester", objNull];
        _entry set ["requesterUID", ""];
        _entry set ["requestId", -1];
        _vehicle setVariable ["Waldo_TransportService_RequestId", -1, true];
        _vehicle setVariable ["Waldo_TransportService_State", "AVAILABLE", true];
        _vehicle setVariable ["Waldo_TransportService_RequesterUID", "", true];
        _vehicle setDir (_entry get "startDir");
        if (_config getOrDefault ["refuelAtBase", true]) then {_vehicle setFuel 1};
        if (_config getOrDefault ["repairAtBase", false]) then {_vehicle setDamage 0};
        _vehicle engineOn false;
        private _group = group driver _vehicle;
        [_group, getPosATL _vehicle, _vehicle, -1, false] remoteExecCall ["Waldo_fnc_TransportStopGroupLocal", groupOwner _group];
    };
};
_services set [_id, _entry];
missionNamespace setVariable ["Waldo_Transport_Services", _services];
true

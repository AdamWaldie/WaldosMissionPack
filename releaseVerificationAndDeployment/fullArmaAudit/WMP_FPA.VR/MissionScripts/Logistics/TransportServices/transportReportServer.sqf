/*
 * Author: WaldoTheWarfighter, Val
 * Accepts arrival/failure reports from the AI locality owner and advances the authoritative state
 * only when service ID, request ID and phase still match. Pickup arrivals wait for a destination;
 * destination arrivals wait until the vehicle is continuously settled and all human occupants in
 * every seat have disembarked, then order RTB; the configured dwell can request an exit but can
 * never authorise an occupied departure. RTB arrivals restore availability. Failed physical RTB may use
 * the explicitly configured empty-vehicle fail-safe reset.
 *
 * Locality, authority, repeat and JIP behaviour:
 * Server only. Reports are accepted solely from the current driver-group owner. Request IDs reject
 * late or duplicate reports after retargeting. Destination waiting observes live human occupants in
 * every fullCrew role while allowing the AI service crew to remain. The automatic RTB transition is explicitly
 * handed to server owner 2 so it cannot inherit and then fail the AI owner's client-authority check.
 * Passenger presence is derived from fullCrew with empty seats excluded, covering every occupied
 * driver, commander, turret, FFV and cargo role. RTB requires both a continuously settled vehicle
 * and a continuously empty human-occupant list; an early GetOut while the aircraft is still landing
 * therefore cannot trigger departure.
 * Public service state remains available to JIP clients; no waiting worker is replayed on clients.
 *
 * Arguments:
 * 0: service ID <STRING>.
 * 1: request ID <NUMBER> - current authoritative serial.
 * 2: phase <STRING> - PICKUP, DESTINATION or RTB.
 * 3: result <STRING> - ARRIVED or FAILED.
 *
 * Return Value: <BOOL> - true when the current request was advanced.
 *
 * Current caller: Waldo_fnc_TransportDispatchLocal on the current AI-group owner.
 *
 * Example:
 * ["RAVEN_1", 12, "PICKUP", "ARRIVED"] remoteExecCall ["Waldo_fnc_TransportReportServer", 2];
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
        [_group, getPosATL _vehicle, _vehicle] remoteExecCall ["Waldo_fnc_TransportStopGroupLocal", groupOwner _group];
        if (!isNull _requester) then {[_type, format ["%1 is ready for boarding. Enter the transport and select a destination through WMP Transport.", _entry get "name"], "SUCCESS", _id] remoteExecCall ["Waldo_fnc_TransportNotifyLocal", owner _requester]};
        [_id, _requestId, _config getOrDefault ["boardingSeconds", 300]] spawn {
            params ["_id", "_requestId", "_seconds"];
            private _deadline = serverTime + (_seconds max 15);
            waitUntil {
                sleep 5;
                private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
                private _entry = _services getOrDefault [_id, createHashMap];
                if (_entry isEqualTo createHashMap || {_entry getOrDefault ["requestId", -1] != _requestId} || {_entry getOrDefault ["state", ""] != "BOARDING"}) exitWith {true};
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
        [_group, getPosATL _vehicle, _vehicle] remoteExecCall ["Waldo_fnc_TransportStopGroupLocal", groupOwner _group];
        [format ["%1 reached the destination. Dismount when ready.", _entry get "name"], "SUCCESS"] call _notifyTransportAudience;
        [_id, _requestId] spawn {
            params ["_id", "_requestId"];
            private _currentPlayerOccupants = {
                params ["_vehicle"];
                // Official fullCrew format begins with the unit occupying each seat. The empty-seat
                // flag is false, so every returned row is an actual driver/turret/FFV/cargo occupant.
                ((fullCrew [_vehicle, "", false]) apply {_x select 0}) select {
                    !isNull _x && {isPlayer _x}
                }
            };
            private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
            private _entry = _services getOrDefault [_id, createHashMap];
            if (_entry isEqualTo createHashMap) exitWith {};
            private _vehicle = _entry get "vehicle";
            private _config = _entry get "config";
            private _deadline = serverTime + (_config getOrDefault ["destinationDwell", 45]);
            private _settleSeconds = (missionNamespace getVariable ["Waldo_Transport_DestinationSettleSeconds", 3]) max 0.5;
            private _emptySeconds = (missionNamespace getVariable ["Waldo_Transport_DestinationEmptyConfirmSeconds", 2]) max 0.5;
            private _settleSpeed = (missionNamespace getVariable ["Waldo_Transport_DestinationSettleSpeedKph", 5]) max 0;
            private _settledSince = -1;
            private _emptySince = -1;
            private _forceIssued = false;
            private _cancelled = false;
            private _remainingPlayers = [];
            waitUntil {
                sleep 0.25;
                _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
                _entry = _services getOrDefault [_id, createHashMap];
                if (
                    _entry isEqualTo createHashMap
                    || {_entry getOrDefault ["requestId", -1] != _requestId}
                    || {_entry getOrDefault ["state", ""] != "DISEMBARKING"}
                ) exitWith {_cancelled = true; true};
                _vehicle = _entry get "vehicle";
                _config = _entry get "config";
                if (!alive _vehicle || {isNull driver _vehicle} || {!alive driver _vehicle}) exitWith {
                    _cancelled = true;
                    true
                };
                _remainingPlayers = [_vehicle] call _currentPlayerOccupants;
                private _speedKph = vectorMagnitude velocity _vehicle * 3.6;
                private _grounded = isTouchingGround _vehicle || {(getPosATL _vehicle select 2) < 0.5};
                if (_grounded && {_speedKph <= _settleSpeed}) then {
                    if (_settledSince < 0) then {_settledSince = serverTime};
                } else {
                    _settledSince = -1;
                };
                if (_remainingPlayers isEqualTo []) then {
                    if (_emptySince < 0) then {_emptySince = serverTime};
                } else {
                    _emptySince = -1;
                };
                // Dwell is now the optional forced-exit prompt, never permission to take off with
                // somebody aboard. After moveOut WMP still waits for fullCrew to become human-empty.
                if (
                    !_forceIssued
                    && {serverTime >= _deadline}
                    && {!(_remainingPlayers isEqualTo [])}
                    && {_config getOrDefault ["forceDisembark", false]}
                ) then {
                    {[_x] remoteExecCall ["moveOut", owner _x]} forEach _remainingPlayers;
                    _forceIssued = true;
                    diag_log format ["[WMP TRANSPORT] Destination dwell expired; requested passenger exit service=%1 request=%2 players=%3.", _id, _requestId, count _remainingPlayers];
                };
                private _settled = _settledSince >= 0 && {serverTime - _settledSince >= _settleSeconds};
                private _empty = _emptySince >= 0 && {serverTime - _emptySince >= _emptySeconds};
                _settled && _empty
            };
            if (_cancelled) exitWith {};
            _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
            _entry = _services getOrDefault [_id, createHashMap];
            if (
                _entry isEqualTo createHashMap
                || {_entry getOrDefault ["requestId", -1] != _requestId}
                || {_entry getOrDefault ["state", ""] != "DISEMBARKING"}
                || {!alive (_entry get "vehicle")}
            ) exitWith {};
            _vehicle = _entry get "vehicle";
            diag_log format [
                "[WMP TRANSPORT] Destination settled and human-empty; requesting RTB service=%1 request=%2 settleSeconds=%3 emptySeconds=%4 speed=%5kph.",
                _id, _requestId, _settleSeconds, _emptySeconds, round (vectorMagnitude velocity _vehicle * 3.6)
            ];
            [_id, _requestId] remoteExecCall ["Waldo_fnc_TransportAutoRtbServer", 2];
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
        _vehicle setVariable ["Waldo_TransportService_Requester", objNull, true];
        _vehicle setDir (_entry get "startDir");
        if (_config getOrDefault ["refuelAtBase", true]) then {_vehicle setFuel 1};
        if (_config getOrDefault ["repairAtBase", false]) then {_vehicle setDamage 0};
        _vehicle engineOn false;
        private _group = group driver _vehicle;
        [_group, getPosATL _vehicle, _vehicle] remoteExecCall ["Waldo_fnc_TransportStopGroupLocal", groupOwner _group];
    };
};
_services set [_id, _entry];
missionNamespace setVariable ["Waldo_Transport_Services", _services];
true

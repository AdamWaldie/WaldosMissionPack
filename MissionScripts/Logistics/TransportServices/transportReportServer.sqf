/*
 * Author: WaldoTheWarfighter, Val
 * Accepts arrival/failure reports from the AI locality owner and advances the authoritative state
 * only when service ID, request ID and phase still match. Pickup arrivals wait for a destination;
 * destination arrivals wait until all player passengers have disembarked or the configured dwell
 * timeout expires, then order RTB; RTB arrivals restore availability. Failed physical RTB may use
 * the explicitly configured empty-vehicle fail-safe reset.
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
            private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
            private _entry = _services getOrDefault [_id, createHashMap];
            if (_entry isEqualTo createHashMap) exitWith {};
            private _vehicle = _entry get "vehicle";
            private _config = _entry get "config";
            private _deadline = serverTime + (_config getOrDefault ["destinationDwell", 45]);
            waitUntil {
                sleep 1;
                _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
                _entry = _services getOrDefault [_id, createHashMap];
                if (
                    _entry isEqualTo createHashMap
                    || {_entry getOrDefault ["requestId", -1] != _requestId}
                    || {_entry getOrDefault ["state", ""] != "DISEMBARKING"}
                ) exitWith {true};
                _vehicle = _entry get "vehicle";
                _config = _entry get "config";
                private _baseCrew = _entry getOrDefault ["baseCrew", []];
                private _playerPassengers = (crew _vehicle) select {!(_x in _baseCrew) && {isPlayer _x}};
                _playerPassengers isEqualTo [] || {serverTime >= _deadline} || {!alive _vehicle}
            };
            _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
            _entry = _services getOrDefault [_id, createHashMap];
            if (
                _entry isEqualTo createHashMap
                || {_entry getOrDefault ["requestId", -1] != _requestId}
                || {_entry getOrDefault ["state", ""] != "DISEMBARKING"}
                || {!alive (_entry get "vehicle")}
            ) exitWith {};
            _vehicle = _entry get "vehicle";
            private _baseCrew = _entry getOrDefault ["baseCrew", []];
            private _remainingPlayers = (crew _vehicle) select {!(_x in _baseCrew) && {isPlayer _x}};
            // Optional forced exit remains explicit. Give moveOut a short physical-exit grace so
            // the aircraft does not receive RTB in the same frame passengers are ordered out.
            if (!(_remainingPlayers isEqualTo []) && {_config getOrDefault ["forceDisembark", false]}) then {
                {[_x] remoteExecCall ["moveOut", owner _x]} forEach _remainingPlayers;
                private _exitDeadline = serverTime + 10;
                waitUntil {
                    sleep 0.25;
                    _remainingPlayers = (crew _vehicle) select {!(_x in _baseCrew) && {isPlayer _x}};
                    _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
                    _entry = _services getOrDefault [_id, createHashMap];
                    _remainingPlayers isEqualTo []
                    || {serverTime >= _exitDeadline}
                    || {!alive _vehicle}
                    || {_entry isEqualTo createHashMap}
                    || {_entry getOrDefault ["requestId", -1] != _requestId}
                    || {_entry getOrDefault ["state", ""] != "DISEMBARKING"}
                };
            };
            _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
            _entry = _services getOrDefault [_id, createHashMap];
            if (
                _entry isEqualTo createHashMap
                || {_entry getOrDefault ["requestId", -1] != _requestId}
                || {_entry getOrDefault ["state", ""] != "DISEMBARKING"}
                || {!alive (_entry get "vehicle")}
            ) exitWith {};
            _vehicle = _entry get "vehicle";
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

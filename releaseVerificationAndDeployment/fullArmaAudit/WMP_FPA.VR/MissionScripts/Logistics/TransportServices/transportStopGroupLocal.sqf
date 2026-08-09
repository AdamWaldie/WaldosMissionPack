/*
 * Author: WaldoTheWarfighter, Val
 * Clears WMP transport waypoints and stops an AI service group on its current locality owner.
 * For a helicopter pickup or destination, it also owns a repeat-safe landed hold for the current
 * request. The hold disables AI movement, continually preserves the engine LAND order and (when
 * configured) keeps the engine running until the next request replaces the request ID. This
 * prevents a completed TR UNLOAD waypoint from alternately lifting and landing while passengers
 * board or disembark. RTB uses the same waypoint cleanup without an away hold or running engine.
 *
 * Arguments:
 * 0: service group <GROUP>
 * 1: stop position ATL <ARRAY> (informational)
 * 2: service vehicle <OBJECT> (default objNull)
 * 3: authoritative request ID <NUMBER> (default -1; no landed hold)
 * 4: keep helicopter engine running away from base <BOOL> (default false)
 * Return Value: Boolean - true on the owning machine.
 * Example: [_group, getPosATL _heli, _heli, 12, true] call Waldo_fnc_TransportStopGroupLocal;
 * Current caller: Waldo_fnc_TransportReportServer after pickup, destination and physical RTB.
 */
params [
    "_group",
    ["_position", [], [[]]],
    ["_vehicle", objNull, [objNull]],
    ["_requestId", -1, [0]],
    ["_keepEngineOn", false, [true]]
];
if (isNull _group) exitWith {false};
if (!local _group) exitWith {
    [_group, _position, _vehicle, _requestId, _keepEngineOn] remoteExecCall ["Waldo_fnc_TransportStopGroupLocal", groupOwner _group];
    true
};
if (_requestId >= 0 && {!isNull _vehicle} && {_vehicle getVariable ["Waldo_TransportService_RequestId", -1] != _requestId}) exitWith {
    diag_log format ["[WMP TRANSPORT] Stale grounded hold rejected vehicle=%1 request=%2 currentRequest=%3 owner=%4", netId _vehicle, _requestId, _vehicle getVariable ["Waldo_TransportService_RequestId", -1], clientOwner];
    false
};
for "_i" from ((count waypoints _group) - 1) to 0 step -1 do {deleteWaypoint [_group, _i]};
private _awayHelicopterHold = !isNull _vehicle && {_vehicle isKindOf "Helicopter"} && {_requestId >= 0};
// doStop is appropriate for ground vehicles and a completed RTB, but it also tells an AI pilot it
// has no pending movement. During an away landing that order can idle the turbine even while WMP
// repeatedly calls engineOn true. MOVE/PATH suspension below is sufficient to prevent lift-off
// without issuing the engine-shutdown-prone stop order.
if !(_awayHelicopterHold) then {doStop leader _group};
if (!isNull _vehicle && {_vehicle isKindOf "Helicopter"}) then {
    _vehicle land "LAND";
    if (_keepEngineOn) then {_vehicle engineOn true};
    if (_requestId >= 0) then {
        private _holdToken = format ["%1:%2", _requestId, diag_frameNo];
        _vehicle setVariable ["Waldo_TransportService_LocalHoldToken", _holdToken];
        _vehicle disableAI "MOVE";
        _vehicle disableAI "PATH";
        driver _vehicle disableAI "MOVE";
        driver _vehicle disableAI "PATH";
        diag_log format ["[WMP TRANSPORT] Grounded away hold started vehicle=%1 request=%2 engineOn=%3 owner=%4", netId _vehicle, _requestId, _keepEngineOn, clientOwner];
        [_vehicle, _group, _position, _requestId, _keepEngineOn, _holdToken] spawn {
            params ["_vehicle", "_group", "_position", "_requestId", "_keepEngineOn", "_holdToken"];
            while {
                !isNull _vehicle
                && {alive _vehicle}
                && {local _group}
                && {_vehicle getVariable ["Waldo_TransportService_RequestId", -1] == _requestId}
                && {_vehicle getVariable ["Waldo_TransportService_LocalHoldToken", ""] == _holdToken}
            } do {
                _vehicle land "LAND";
                if (_keepEngineOn) then {_vehicle engineOn true};
                uiSleep 0.25;
            };
            diag_log format ["[WMP TRANSPORT] Grounded away hold released vehicle=%1 request=%2 currentRequest=%3 owner=%4", netId _vehicle, _requestId, _vehicle getVariable ["Waldo_TransportService_RequestId", -1], clientOwner];
            // AI ownership can migrate to a headless client/server while passengers are boarding.
            // Reinstall the same current hold on the new group owner instead of silently releasing it.
            if (
                !isNull _vehicle
                && {alive _vehicle}
                && {!local _group}
                && {_vehicle getVariable ["Waldo_TransportService_RequestId", -1] == _requestId}
                && {_vehicle getVariable ["Waldo_TransportService_LocalHoldToken", ""] == _holdToken}
            ) then {
                [_group, _position, _vehicle, _requestId, _keepEngineOn] remoteExecCall ["Waldo_fnc_TransportStopGroupLocal", groupOwner _group];
            };
            if (!isNull _vehicle && {_vehicle getVariable ["Waldo_TransportService_LocalHoldToken", ""] == _holdToken}) then {
                _vehicle setVariable ["Waldo_TransportService_LocalHoldToken", ""];
            };
        };
    };
};
true

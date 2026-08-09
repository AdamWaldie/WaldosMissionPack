/*
 * Author: WaldoTheWarfighter, Val
 * Clears WMP transport waypoints and stops an AI service group on its current locality owner.
 * For a helicopter pickup or destination, it also owns a repeat-safe landed hold for the current
 * request. The hold continually preserves the engine LAND order until the next request replaces
 * the request ID; this prevents a completed TR UNLOAD waypoint from lifting the aircraft back into
 * a hover while passengers board or disembark. RTB uses the same stop without an away hold.
 *
 * Arguments:
 * 0: service group <GROUP>
 * 1: stop position ATL <ARRAY> (informational)
 * 2: service vehicle <OBJECT> (default objNull)
 * 3: authoritative request ID <NUMBER> (default -1; no landed hold)
 * 4: keep helicopter engine running away from base <BOOL> (default false)
 * Return Value: Boolean - true on the owning machine.
 * Example: [_group, getPosATL _heli, _heli, 12, true] call Waldo_fnc_TransportStopGroupLocal;
 * Current caller: Waldo_fnc_TransportReportServer after physical RTB.
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
for "_i" from ((count waypoints _group) - 1) to 0 step -1 do {deleteWaypoint [_group, _i]};
doStop leader _group;
if (!isNull _vehicle && {_vehicle isKindOf "Helicopter"}) then {
    _vehicle land "LAND";
    if (_keepEngineOn) then {_vehicle engineOn true};
    if (_requestId >= 0) then {
        private _holdToken = format ["%1:%2", _requestId, diag_frameNo];
        _vehicle setVariable ["Waldo_TransportService_LocalHoldToken", _holdToken];
        [_vehicle, _group, _requestId, _keepEngineOn, _holdToken] spawn {
            params ["_vehicle", "_group", "_requestId", "_keepEngineOn", "_holdToken"];
            while {
                !isNull _vehicle
                && {alive _vehicle}
                && {local _group}
                && {_vehicle getVariable ["Waldo_TransportService_RequestId", -1] == _requestId}
                && {_vehicle getVariable ["Waldo_TransportService_LocalHoldToken", ""] == _holdToken}
            } do {
                _vehicle land "LAND";
                doStop driver _vehicle;
                if (_keepEngineOn) then {_vehicle engineOn true};
                sleep 2;
            };
            if (!isNull _vehicle && {_vehicle getVariable ["Waldo_TransportService_LocalHoldToken", ""] == _holdToken}) then {
                _vehicle setVariable ["Waldo_TransportService_LocalHoldToken", ""];
            };
        };
    };
};
true

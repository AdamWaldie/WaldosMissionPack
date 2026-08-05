/*
 * Author: WaldoTheWarfighter, Val
 * Validates and atomically reserves transport services on the server. Typed pools prevent ground
 * and helicopter requests from competing. Every accepted task receives a monotonic request ID;
 * later arrival/failure reports must match it, so delayed locality messages cannot corrupt a newer
 * task. Access rules are validated against the requesting player's live side/group/leadership.
 *
 * Arguments:
 * 0: action <STRING> - REQUEST_PICKUP, SET_DESTINATION or RTB.
 * 1: service type <STRING> - HELICOPTER or GROUND.
 * 2: vehicle <OBJECT> - required for destination/RTB; ignored for pickup.
 * 3: map position <ARRAY> - pickup/destination position.
 * 4: requester <OBJECT> - player making the request.
 *
 * Return Value: Boolean - true when accepted.
 *
 * Example:
 * ["REQUEST_PICKUP", "GROUND", objNull, getPosATL player, player] remoteExecCall ["Waldo_fnc_TransportRequestServer", 2];
 * Result: reserves the nearest eligible available ground taxi and dispatches its local AI group.
 * Current caller: Waldo_fnc_TransportOpenMapLocal and the RTB self-action.
 */

params ["_action", "_type", "_vehicle", ["_position", [], [[]]], "_requester"];
_action = toUpperANSI _action;
_type = toUpperANSI _type;
private _internalRtb = remoteExecutedOwner == 0 && {_action == "RTB"};
if (!isServer || {!_internalRtb && {isNull _requester || {!isPlayer _requester}}}) exitWith {false};
if (remoteExecutedOwner > 0 && {owner _requester != remoteExecutedOwner}) exitWith {false};
if !(missionNamespace getVariable ["Waldo_TransportServices_Enable", false]) exitWith {false};
if !(_type in ["HELICOPTER", "GROUND"]) exitWith {false};
private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
private _entry = createHashMap;
private _id = "";

private _canUse = {
    params ["_candidate", "_requester"];
    private _config = _candidate get "config";
    private _allowedSides = _config getOrDefault ["allowedSides", []];
    private _sideAllowed = _allowedSides isEqualTo [] || {side group _requester in _allowedSides};
    private _allowedGroups = _config getOrDefault ["allowedGroups", []];
    private _groupAllowed = _allowedGroups isEqualTo [] || {toUpperANSI groupId group _requester in (_allowedGroups apply {toUpperANSI _x})};
    private _leaderAllowed = !(_config getOrDefault ["leadersOnly", false]) || {leader group _requester == _requester};
    _sideAllowed && _groupAllowed && _leaderAllowed
};

if (_action == "REQUEST_PICKUP") then {
    if (count _position < 2) exitWith {false};
    private _pool = (missionNamespace getVariable ["Waldo_Transport_Pools", createHashMap]) getOrDefault [_type, []];
    private _bestDistance = 1e12;
    {
        private _candidate = _services getOrDefault [_x, createHashMap];
        private _candidateVehicle = _candidate getOrDefault ["vehicle", objNull];
        if (
            !isNull _candidateVehicle && {alive _candidateVehicle} && {alive driver _candidateVehicle}
            && {_candidate getOrDefault ["state", ""] == "AVAILABLE"}
            && {[_candidate, _requester] call _canUse}
        ) then {
            private _distance = _candidateVehicle distance2D _position;
            if (_distance < _bestDistance) then {_bestDistance = _distance; _entry = _candidate; _id = _x};
        };
    } forEach _pool;
    if (_id == "") exitWith {
        [_type, "No eligible service is currently available.", "WARNING"] remoteExecCall ["Waldo_fnc_TransportNotifyLocal", owner _requester];
        false
    };
} else {
    if (isNull _vehicle) exitWith {false};
    _id = _vehicle getVariable ["Waldo_TransportService_Id", ""];
    _entry = _services getOrDefault [_id, createHashMap];
    if (_entry isEqualTo createHashMap) exitWith {false};
    if (!_internalRtb && {!([_entry, _requester] call _canUse)}) exitWith {false};
    if (!_internalRtb && {!(_requester in crew _vehicle || {!isNull getAssignedCuratorLogic _requester})}) exitWith {false};
};

_vehicle = _entry get "vehicle";
private _config = _entry get "config";
private _state = _entry getOrDefault ["state", "AVAILABLE"];
private _phase = "";
private _target = _position;
switch (_action) do {
    case "REQUEST_PICKUP": {_phase = "PICKUP"};
    case "SET_DESTINATION": {
        if (_state != "BOARDING" || {count _position < 2}) exitWith {};
        _phase = "DESTINATION";
    };
    case "RTB": {_phase = "RTB"; _target = _entry get "startPos"};
};
if (_phase == "") exitWith {false};

if (_type == "GROUND") then {
    private _roads = _target nearRoads 120;
    if !(_roads isEqualTo []) then {
        private _nearest = _roads select 0;
        {if (_x distance2D _target < _nearest distance2D _target) then {_nearest = _x}} forEach _roads;
        _target = getPosATL _nearest;
    };
} else {
    private _safe = [_target, 5, 500, 15, 0, 0.5, 0] call BIS_fnc_findSafePos;
    if !(_safe isEqualTo [0, 0, 0]) then {_target = _safe};
};

private _serial = (missionNamespace getVariable ["Waldo_Transport_RequestSerial", 0]) + 1;
missionNamespace setVariable ["Waldo_Transport_RequestSerial", _serial];
_entry set ["requestId", _serial];
_entry set ["requester", _requester];
_entry set ["state", switch (_phase) do {case "PICKUP": {"TO_PICKUP"}; case "DESTINATION": {"TO_DESTINATION"}; default {"RTB"}}];
_entry set ["phaseStarted", serverTime];
_entry set ["target", _target];
_services set [_id, _entry];
missionNamespace setVariable ["Waldo_Transport_Services", _services];
_vehicle setVariable ["Waldo_TransportService_State", _entry get "state", true];
private _destinationMarker = format ["Waldo_Transport_Destination_%1", _id];
deleteMarker _destinationMarker;
createMarker [_destinationMarker, _target];
_destinationMarker setMarkerType "mil_end";
_destinationMarker setMarkerText format ["%1 %2", _entry get "name", toLowerANSI _phase];
private _requestSide = if (_internalRtb) then {side driver _vehicle} else {side group _requester};
_destinationMarker setMarkerColor (switch (_requestSide) do {case west: {"ColorWEST"}; case east: {"ColorEAST"}; case independent: {"ColorGUER"}; default {"ColorCIV"}});
_entry set ["destinationMarker", _destinationMarker];
_services set [_id, _entry];
missionNamespace setVariable ["Waldo_Transport_Services", _services];

if (!isNull _requester) then {[_type, format ["%1 accepted the %2 request.", _entry get "name", toLowerANSI _phase], "INFO"] remoteExecCall ["Waldo_fnc_TransportNotifyLocal", owner _requester]};
[_vehicle, _id, _serial, _phase, _target, _config] remoteExecCall ["Waldo_fnc_TransportDispatchLocal", groupOwner group driver _vehicle];
true

/*
 * Author: WaldoTheWarfighter, Val
 * Validates and atomically reserves transport services on the server. Typed pools prevent ground
 * and helicopter requests from competing. Every accepted task receives a monotonic request ID;
 * later arrival/failure reports must match it, so delayed locality messages cannot corrupt a newer
 * task. Access rules are validated against the requesting player's live side/group/leadership.
 *
 * Arguments:
 * 0: action <STRING> - REQUEST_PICKUP, REQUEST_ADDITIONAL, REQUEST_SPECIFIC (internal bulk use),
 *    MOVE_PICKUP, SET_DESTINATION, RETRY or RTB.
 * 1: service type <STRING> - HELICOPTER or GROUND.
 * 2: vehicle <OBJECT> - required for destination/RTB; ignored for pickup.
 * 3: map position <ARRAY> - pickup/destination position.
 * 4: requester <OBJECT> - player making the request.
 * 5: suppress requester notification <BOOL> - internal bulk calls use true so one fleet summary
 *    replaces one card per vehicle.
 *
 * Return Value: Boolean - true when accepted.
 *
 * Example:
 * ["REQUEST_PICKUP", "GROUND", objNull, getPosATL player, player] remoteExecCall ["Waldo_fnc_TransportRequestServer", 2];
 * Result: reserves the nearest eligible available ground transport and dispatches its local AI group.
 * Current caller: Waldo_fnc_TransportOpenMapLocal and the RTB self-action.
 */

params ["_action", "_type", "_vehicle", ["_position", [], [[]]], "_requester", ["_suppressRequesterNotification", false, [false]]];
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
private _retargetingPickup = false;
private _retrying = false;
private _requestRejected = false;
private _requesterUid = if (isNull _requester) then {""} else {getPlayerUID _requester};
private _notifyRequester = {
    params ["_type", "_message", "_severity", ["_channel", "TRANSPORT", [""]]];
    if (!_suppressRequesterNotification && {!isNull _requester}) then {
        [_type, _message, _severity, _channel] remoteExecCall ["Waldo_fnc_TransportNotifyLocal", owner _requester];
    };
};

private _canUse = {
    params ["_candidate", "_requester"];
    if (!isNull getAssignedCuratorLogic _requester) exitWith {true};
    private _config = _candidate get "config";
    private _allowedSides = _config getOrDefault ["allowedSides", []];
    private _sideAllowed = _allowedSides isEqualTo [] || {side group _requester in _allowedSides};
    private _allowedGroups = _config getOrDefault ["allowedGroups", []];
    private _groupAllowed = _allowedGroups isEqualTo [] || {toUpperANSI groupId group _requester in (_allowedGroups apply {toUpperANSI _x})};
    private _leaderAllowed = !(_config getOrDefault ["leadersOnly", false]) || {leader group _requester == _requester};
    _sideAllowed && _groupAllowed && _leaderAllowed
};

if (_action in ["REQUEST_PICKUP", "REQUEST_ADDITIONAL"]) then {
    if (count _position < 2) exitWith {false};
    // The normal request safely retargets one existing pickup. Additional requests deliberately
    // reserve another asset, keeping multi-vehicle lifts possible without accidental duplication.
    private _ownedIds = (keys _services) select {
        private _candidate = _services get _x;
        _candidate getOrDefault ["type", ""] == _type
        && {_requesterUid != ""}
        && {_candidate getOrDefault ["requesterUID", ""] == _requesterUid}
        && {_candidate getOrDefault ["state", "AVAILABLE"] != "AVAILABLE"}
    };
    if (_action == "REQUEST_PICKUP" && {count _ownedIds > 1}) exitWith {
        [_type, "You have several active transports of this type. Use Select / Manage Transport and choose the named vehicle you want to control.", "WARNING"] call _notifyRequester;
        _requestRejected = true
    };
    if (_action == "REQUEST_PICKUP" && {count _ownedIds == 1}) then {
        _id = _ownedIds select 0;
        private _owned = _services get _id;
        private _ownedState = _owned getOrDefault ["state", ""];
        if !(_ownedState in ["TO_PICKUP", "BOARDING"]) exitWith {
            [_type, format ["%1 is already handling your request (%2). Use Select / Manage Transport to control it or select another available vehicle.", _owned get "name", _ownedState], "WARNING"] call _notifyRequester;
            _requestRejected = true;
            _id = ""
        };
        _entry = _owned;
        _retargetingPickup = true;
    };
    if (!_requestRejected) then {
    if (_retargetingPickup) then {
        _vehicle = _entry get "vehicle";
    } else {
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
        [_type, "No eligible transport is currently available.", "WARNING"] call _notifyRequester;
        _requestRejected = true
    };
    };
    };
} else {
    if (isNull _vehicle) exitWith {_requestRejected = true};
    _id = _vehicle getVariable ["Waldo_TransportService_Id", ""];
    _entry = _services getOrDefault [_id, createHashMap];
    if (_entry isEqualTo createHashMap) exitWith {_requestRejected = true};
    if (!_internalRtb && {!([_entry, _requester] call _canUse)}) exitWith {_requestRejected = true};
    private _isCurator = !isNull getAssignedCuratorLogic _requester;
    private _isCrew = _requester in crew _vehicle;
    private _ownsRequest = _requesterUid != "" && {_entry getOrDefault ["requesterUID", ""] == _requesterUid};
    private _actionAllowed = switch (_action) do {
        case "REQUEST_SPECIFIC": {_entry getOrDefault ["state", ""] == "AVAILABLE"};
        case "MOVE_PICKUP": {_isCurator || {_ownsRequest}};
        case "SET_DESTINATION": {_isCurator || {_isCrew}};
        case "RETRY": {_isCurator || {_isCrew} || {_ownsRequest}};
        case "RTB": {_isCurator || {_isCrew} || {_ownsRequest}};
        default {false};
    };
    if (!_internalRtb && {!_actionAllowed}) exitWith {
        [_type, format ["You cannot control %1. Use the named transport reserved by you, a transport you are travelling in, or Zeus control.", _entry getOrDefault ["name", "this transport"]], "WARNING"] call _notifyRequester;
        _requestRejected = true
    };
};
if (_requestRejected || {_id == ""}) exitWith {false};

_vehicle = _entry get "vehicle";
private _config = _entry get "config";
private _state = _entry getOrDefault ["state", "AVAILABLE"];
private _phase = "";
private _target = _position;
switch (_action) do {
    case "REQUEST_PICKUP": {_phase = "PICKUP"};
    case "REQUEST_ADDITIONAL": {_phase = "PICKUP"};
    case "REQUEST_SPECIFIC": {_phase = "PICKUP"};
    case "MOVE_PICKUP": {
        if (!(_state in ["TO_PICKUP", "BOARDING"]) || {count _position < 2}) exitWith {};
        _phase = "PICKUP";
        _retargetingPickup = true;
    };
    case "SET_DESTINATION": {
        // Symmetric with MOVE_PICKUP retargeting a still-inbound pickup: a destination already
        // being travelled to can be changed too, not just the first one picked while boarding.
        // The same fresh-serial/requestId mechanism below invalidates any superseded AI-owner
        // loop before it can land, stop or report against the old destination.
        if !(_state in ["BOARDING", "TO_DESTINATION"]) exitWith {};
        if (count _position < 2) exitWith {};
        _phase = "DESTINATION";
    };
    case "RETRY": {
        if (_state != "STUCK") exitWith {};
        _phase = _entry getOrDefault ["lastFailedPhase", ""];
        _target = _entry getOrDefault ["target", []];
        if !(_phase in ["PICKUP", "DESTINATION", "RTB"] && {count _target >= 2}) then {_phase = ""};
        _retrying = _phase != "";
    };
    case "RTB": {_phase = "RTB"; _target = _entry get "startPos"};
};
if (_phase == "") exitWith {false};
private _requestedTarget = +_target;
private _targetValid = true;
private _targetFailure = "";
private _minimumSeparation = _config getOrDefault ["minimumSeparation", if (_type == "HELICOPTER") then {60} else {18}];
private _occupiedTargets = [];
{
    if (_x != _id) then {
        private _other = _services get _x;
        if (_other getOrDefault ["type", ""] == _type && {_other getOrDefault ["state", "AVAILABLE"] != "AVAILABLE"}) then {
            private _otherTarget = _other getOrDefault ["target", []];
            if (count _otherTarget >= 2) then {_occupiedTargets pushBack _otherTarget};
        };
    };
} forEach keys _services;
private _isSeparated = {
    params ["_candidate"];
    _occupiedTargets findIf {_candidate distance2D _x < _minimumSeparation} < 0
};

// RTB means the exact registered base, not another generic service point. Registration already
// rejects overlapping base footprints. Running the ordinary safe-position search here moved
// helicopters away from their own pads and could leave them permanently in RTB.
if (_phase == "RTB") then {
    _target = +(_entry get "startPos");
} else {
if (_type == "GROUND") then {
    private _roads = _target nearRoads (_config getOrDefault ["roadSearchRadius", 200]);
    if !(_roads isEqualTo []) then {
        private _connected = _roads select {count (roadsConnectedTo _x) > 0};
        private _candidates = if (_connected isEqualTo []) then {_roads} else {_connected};
        _candidates = [_candidates, [], {_x distance2D _target}, "ASCEND"] call BIS_fnc_sortBy;
        private _resolved = [];
        {
            private _roadPosition = getPosATL _x;
            private _clearPosition = _roadPosition findEmptyPosition [0, (_minimumSeparation max 12), typeOf _vehicle];
            if (_clearPosition isEqualTo []) then {_clearPosition = _roadPosition};
            if ([_clearPosition] call _isSeparated) exitWith {_resolved = _clearPosition};
        } forEach _candidates;
        if (_resolved isEqualTo []) then {_targetValid = false} else {_target = _resolved};
    } else {
        private _clearPosition = _target findEmptyPosition [0, (_minimumSeparation max 12), typeOf _vehicle];
        if !(_clearPosition isEqualTo []) then {_target = _clearPosition};
        if !([_target] call _isSeparated) then {_targetValid = false};
    };
} else {
    private _maximumRadius = _config getOrDefault ["landingSearchRadius", 250];
    private _clearanceScale = (_config getOrDefault ["landingClearanceScale", 2.0]) max 1;
    private _bounds = boundingBoxReal _vehicle;
    _bounds params ["_boundsMinimum", "_boundsMaximum"];
    private _vehicleWidth = abs ((_boundsMaximum select 0) - (_boundsMinimum select 0));
    private _vehicleLength = abs ((_boundsMaximum select 1) - (_boundsMinimum select 1));
    private _clearanceHalfWidth = ((_vehicleWidth * _clearanceScale) * 0.5) max 1.5;
    private _clearanceHalfLength = ((_vehicleLength * _clearanceScale) * 0.5) max 1.5;
    // The engine clearance test accepts a circular object-clearance distance. Circumscribing the
    // scaled model selection box is conservative, but guarantees that the complete footprint fits.
    private _clearanceRadius = sqrt ((_clearanceHalfWidth ^ 2) + (_clearanceHalfLength ^ 2));
    private _safe = [];
    private _isExactLzSafe = {
        params ["_candidate"];
        if (surfaceIsWater _candidate || {!([_candidate] call _isSeparated)}) exitWith {false};
        // isFlatEmpty validates the position supplied; unlike BIS_fnc_findSafePos it does not
        // silently choose a different point. Ignore the requested aircraft itself and people who
        // are expected to be standing at a pickup click, but reject another parked vehicle.
        private _flat = _candidate isFlatEmpty [_clearanceRadius min 50, -1, 0.35, _clearanceRadius, 0, false, _vehicle];
        if (_flat isEqualTo []) exitWith {false};
        private _blockingVehicle = (nearestObjects [_candidate, ["AllVehicles"], _clearanceRadius, true]) findIf {
            _x != _vehicle && {!(_x isKindOf "CAManBase")}
        };
        _blockingVehicle < 0
    };
    if ([_requestedTarget] call _isExactLzSafe) then {
        _safe = [_requestedTarget select 0, _requestedTarget select 1, 0];
    } else {
        // Search deterministic nearest-first rings only after the exact click fails. This avoids
        // the former behaviour where the first check itself was allowed to wander up to 60 m.
        private _searchStep = _clearanceRadius max 5;
        for "_radius" from _searchStep to _maximumRadius step _searchStep do {
            for "_angle" from 0 to 330 step 30 do {
                if (_safe isEqualTo []) then {
                    private _candidate = _requestedTarget getPos [_radius, _angle];
                    if ([_candidate] call _isExactLzSafe) then {
                        _safe = [_candidate select 0, _candidate select 1, 0];
                    };
                };
            };
        };
    };
    if (_safe isEqualTo []) then {
        _targetFailure = format ["No safe landing zone large enough for this helicopter's %1 x %2 metre clearance footprint was found within %3 metres of the selected point.", round (_clearanceHalfWidth * 2), round (_clearanceHalfLength * 2), round _maximumRadius];
        _targetValid = false;
    } else {
        _target = _safe;
        diag_log format ["[WMP TRANSPORT] LZ clearance service=%1 aircraft=%2 model=%3x%4 scale=%5 required=%6x%7 radius=%8", _id, typeOf _vehicle, round _vehicleWidth, round _vehicleLength, _clearanceScale, round (_clearanceHalfWidth * 2), round (_clearanceHalfLength * 2), round _clearanceRadius];
    };
};
};
if (!_targetValid) exitWith {
    if (_targetFailure == "") then {_targetFailure = format ["No clear service point with %1 metres separation was found near the selected position.", round _minimumSeparation]};
    [_type, _targetFailure, "WARNING"] call _notifyRequester;
    false
};

private _oldLandingPad = _entry getOrDefault ["landingPad", objNull];
if (!isNull _oldLandingPad) then {deleteVehicle _oldLandingPad};
_entry deleteAt "landingPad";
private _landingPad = objNull;
if (_type == "HELICOPTER") then {
    _landingPad = createVehicle ["Land_HelipadEmpty_F", _target, [], 0, "CAN_COLLIDE"];
    _landingPad setPosATL _target;
    _entry set ["landingPad", _landingPad];
};

private _serial = (missionNamespace getVariable ["Waldo_Transport_RequestSerial", 0]) + 1;
missionNamespace setVariable ["Waldo_Transport_RequestSerial", _serial];
_entry set ["requestId", _serial];
_vehicle setVariable ["Waldo_TransportService_RequestId", _serial, true];
_entry set ["requester", _requester];
if (!_internalRtb && {_requesterUid != ""}) then {_entry set ["requesterUID", _requesterUid]};
_entry set ["state", switch (_phase) do {case "PICKUP": {"TO_PICKUP"}; case "DESTINATION": {"TO_DESTINATION"}; default {"RTB"}}];
_entry set ["phaseStarted", serverTime];
_entry set ["target", _target];
_services set [_id, _entry];
missionNamespace setVariable ["Waldo_Transport_Services", _services];
_vehicle setVariable ["Waldo_TransportService_State", _entry get "state", true];
_vehicle setVariable ["Waldo_TransportService_RequesterUID", _entry getOrDefault ["requesterUID", ""], true];
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
diag_log format [
    "[WMP TRANSPORT] Accepted service=%1 type=%2 request=%3 phase=%4 requested=%5 resolved=%6 adjustment=%7 owner=%8",
    _id, _type, _serial, _phase, _requestedTarget, _target, round (_requestedTarget distance2D _target), groupOwner group driver _vehicle
];

if (!isNull _requester) then {
    private _adjustment = _requestedTarget distance2D _target;
    private _adjustmentText = if (_adjustment > 10) then {format [" The exact service point was adjusted %1 metres to reachable ground.", round _adjustment]} else {""};
    private _verb = if (_retargetingPickup) then {"updated its pickup point"} else {if (_retrying) then {format ["is retrying its %1 route", toLowerANSI _phase]} else {format ["accepted the %1 request", toLowerANSI _phase]}};
    [_type, format ["%1 %2.%3", _entry get "name", _verb, _adjustmentText], "INFO", _id] call _notifyRequester;
};
[_vehicle, _id, _serial, _phase, _target, _config, _landingPad] remoteExecCall ["Waldo_fnc_TransportDispatchLocal", groupOwner group driver _vehicle];
true

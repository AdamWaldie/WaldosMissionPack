/*
 * Author: WaldoTheWarfighter, Val
 * Executes one validated transport movement on the machine currently owning the AI driver group.
 * It creates only local control state, clears only that group's waypoints, applies the configured
 * non-combat movement policy and reports arrival/failure with the authoritative request ID.
 * Service helicopters retain the proven transport sequence: one TR UNLOAD waypoint followed by
 * the vehicle LAND command inside 300 metres. WMP improved landing is the only addition: when its
 * controller owns the final approach, the original LAND command waits as a fallback instead of
 * fighting the vector controller.
 * Locality and authority: runs only where the AI driver group is local; server request IDs remain authoritative.
 *
 * Arguments: vehicle, service ID, request ID, phase, target ATL position, config HashMap, the
 * server-created invisible landing pad (helicopters only), and an internal retries-remaining
 * counter (default 20) used only by this function's own requestId-replication retry - callers
 * should never pass it.
 * Return Value: Boolean - true when dispatched on the owning machine.
 * Example: [_heli,"RAVEN_1",12,"PICKUP",_lz,_config] call Waldo_fnc_TransportDispatchLocal;
 * Current caller: Waldo_fnc_TransportRequestServer owner-targeted remote execution.
 */
params ["_vehicle", "_id", "_requestId", "_phase", "_target", "_config", ["_landingPad", objNull, [objNull]], ["_retriesRemaining", 20, [0]]];
if (isNull _vehicle || {isNull driver _vehicle}) exitWith {false};
// Waldo_TransportService_RequestId is a broadcast object variable (setVariable [...,true]); this
// call is a directly targeted remoteExecCall the server issues in the same frame it sets that
// variable. Those two network messages travel through separate paths with no ordering guarantee
// between them - the direct call can legitimately arrive here before the broadcast update does,
// which would otherwise make a perfectly valid, brand-new dispatch look stale and silently drop it
// (no waypoint is ever created; the vehicle just sits with whatever orders it had before). Retry
// briefly instead of exiting immediately; a request that is genuinely superseded will still never
// match and correctly gives up once retries run out.
if (_vehicle getVariable ["Waldo_TransportService_RequestId", -1] != _requestId) exitWith {
    if (_retriesRemaining <= 0) exitWith {
        diag_log format ["[WMP TRANSPORT] Dispatch dropped: service=%1 request=%2 requestId never replicated to this machine.", _id, _requestId];
        false
    };
    [_vehicle, _id, _requestId, _phase, _target, _config, _landingPad, _retriesRemaining - 1] spawn {
        params ["_vehicle", "_id", "_requestId", "_phase", "_target", "_config", "_landingPad", "_retriesRemaining"];
        sleep 0.1;
        [_vehicle, _id, _requestId, _phase, _target, _config, _landingPad, _retriesRemaining] call Waldo_fnc_TransportDispatchLocal;
    };
    false
};
private _group = group driver _vehicle;
if (!local _group) exitWith {
    [_vehicle, _id, _requestId, _phase, _target, _config, _landingPad] remoteExecCall ["Waldo_fnc_TransportDispatchLocal", groupOwner _group];
    true
};
for "_i" from ((count waypoints _group) - 1) to 0 step -1 do {deleteWaypoint [_group, _i]};
private _helicopter = _vehicle isKindOf "Helicopter";
private _movementBehaviour = if (_helicopter) then {_config getOrDefault ["behaviour", "CARELESS"]} else {"SAFE"};
_group setBehaviourStrong _movementBehaviour;
_group setCombatMode "BLUE";
_group setSpeedMode (_config getOrDefault ["speedMode", "FULL"]);
// Stop orders persist across deleted/replaced waypoints. Release every crew member before each
// pickup, destination or RTB dispatch so a vehicle stopped in the prior phase can move again.
units _group doFollow leader _group;
_vehicle engineOn true;
if (_helicopter) then {
    if (_vehicle getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]) then {
        [_vehicle, false, ""] call Waldo_fnc_ImprovedHelicopterLandingRestoreLocal;
    };
    _vehicle land "NONE";
    _vehicle flyInHeight ((_config getOrDefault ["cruiseAltitude", 80]) max 20);
} else {
    _vehicle limitSpeed (_config getOrDefault ["groundSpeedLimit", 60]);
    // Prefer the engine's connected-road route when both the vehicle and resolved target are on a
    // road. Off-road requests retain normal terrain pathfinding instead of being pinned to roads.
    private _roadRoute = !((_vehicle nearRoads 30) isEqualTo []) && {!((_target nearRoads 20) isEqualTo [])};
    driver _vehicle forceFollowRoad _roadRoute;
};
// Preserve the original transport mechanic. Radius 0 and TR UNLOAD are intentional here: this is
// the sequence proven by the supplied implementation, with the safe LZ already resolved by server.
private _waypoint = _group addWaypoint [_target, 0];
_waypoint setWaypointType (if (_helicopter) then {"TR UNLOAD"} else {"MOVE"});
_waypoint setWaypointBehaviour _movementBehaviour;
_waypoint setWaypointCombatMode "BLUE";
_waypoint setWaypointSpeed (_config getOrDefault ["speedMode", "FULL"]);
if (!_helicopter) then {
    _waypoint setWaypointCompletionRadius ((_config getOrDefault ["stopRadius", 12]) max 5);
};
_group setCurrentWaypoint _waypoint;
diag_log format ["[WMP TRANSPORT] Local dispatch service=%1 request=%2 phase=%3 target=%4 helicopter=%5 waypoint=%6 type=%7 owner=%8", _id, _requestId, _phase, _target, _helicopter, _waypoint select 1, waypointType _waypoint, clientOwner];

[_vehicle, _id, _requestId, _phase, _target, _config, _helicopter, _landingPad, _waypoint] spawn {
    params ["_vehicle", "_id", "_requestId", "_phase", "_target", "_config", "_helicopter", "_landingPad", "_waypoint"];
    private _group = group driver _vehicle;
    private _stale = {_vehicle getVariable ["Waldo_TransportService_RequestId", -1] != _requestId};
    private _timeout = diag_tickTime + (missionNamespace getVariable ["Waldo_Transport_TravelTimeout", 900]);
    private _stopRadius = (_config getOrDefault ["stopRadius", if (_helicopter) then {35} else {12}]) max 5;
    if (_helicopter) then {
        diag_log format ["[WMP TRANSPORT] Awaiting physical takeoff before final approach service=%1 request=%2 initialDistance=%3", _id, _requestId, round (_vehicle distance2D _target)];
        waitUntil {
            sleep 1;
            call _stale
            || {!local _group}
            || {!alive _vehicle}
            || {!alive driver _vehicle}
            || {!isTouchingGround _vehicle && {_vehicle distance2D _target <= 300}}
            || {diag_tickTime >= _timeout}
        };
        if (!(call _stale) && {local _group} && {alive _vehicle} && {alive driver _vehicle} && {!isTouchingGround _vehicle} && {_vehicle distance2D _target <= 300}) then {
            if !(_vehicle getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]) then {
                _vehicle land "LAND";
            };
        };
        private _fallbackIssued = false;
        waitUntil {
            sleep 1;
            private _touchdown = (isTouchingGround _vehicle || {getPosATL _vehicle select 2 < 1.5}) && {_vehicle distance2D _target <= (_stopRadius * 2)};
            if (
                !_touchdown
                && {!_fallbackIssued}
                && {!(_vehicle getVariable ["Waldo_ImprovedHelicopterLanding_Active", false])}
                && {!isTouchingGround _vehicle}
                && {_vehicle distance2D _target <= 300}
            ) then {
                _vehicle land "LAND";
                _fallbackIssued = true;
                diag_log format ["[WMP TRANSPORT] Original LAND fallback active service=%1 request=%2 distance=%3", _id, _requestId, round (_vehicle distance2D _target)];
            };
            call _stale || {!local _group} || {!alive _vehicle} || {!alive driver _vehicle} || {_touchdown} || {diag_tickTime >= _timeout}
        };
    } else {
        private _bestDistance = _vehicle distance2D _target;
        private _lastProgress = diag_tickTime;
        private _retrySeconds = _config getOrDefault ["pathRetrySeconds", 25];
        private _retriesRemaining = _config getOrDefault ["pathRetryLimit", 3];
        waitUntil {
            sleep 1;
            private _distance = _vehicle distance2D _target;
            if (_distance < (_bestDistance - 5)) then {_bestDistance = _distance; _lastProgress = diag_tickTime};
            if (!(call _stale) && {diag_tickTime - _lastProgress >= _retrySeconds} && {_retriesRemaining > 0} && {alive driver _vehicle} && {local _group}) then {
                units _group doFollow leader _group;
                _group setCurrentWaypoint _waypoint;
                _retriesRemaining = _retriesRemaining - 1;
                _lastProgress = diag_tickTime;
                diag_log format ["[WMP TRANSPORT] Reissued ground path service=%1 request=%2 remaining=%3 distance=%4", _id, _requestId, _retriesRemaining, round _distance];
            };
            call _stale || {!local _group} || {!alive _vehicle} || {!alive driver _vehicle} || {_distance <= _stopRadius} || {diag_tickTime >= _timeout}
        };
        if (!(call _stale) && {alive _vehicle} && {_vehicle distance2D _target <= _stopRadius}) then {doStop driver _vehicle};
    };
    if (call _stale) exitWith {diag_log format ["[WMP TRANSPORT] Superseded controller stopped service=%1 request=%2", _id, _requestId]};
    if (!local _group) exitWith {[_vehicle, _id, _requestId, _phase, _target, _config, _landingPad] remoteExecCall ["Waldo_fnc_TransportDispatchLocal", groupOwner _group]};
    private _arrived = alive _vehicle && {alive driver _vehicle} && {_vehicle distance2D _target <= (_stopRadius * (if (_helicopter) then {2} else {1}))};
    [_id, _requestId, _phase, if (_arrived) then {"ARRIVED"} else {"FAILED"}] remoteExecCall ["Waldo_fnc_TransportReportServer", 2];
};
true

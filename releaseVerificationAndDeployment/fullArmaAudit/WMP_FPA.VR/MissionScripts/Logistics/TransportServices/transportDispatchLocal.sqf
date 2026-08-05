/*
 * Author: WaldoTheWarfighter, Val
 * Executes one validated transport movement on the machine currently owning the AI driver group.
 * It creates only local control state, clears only that group's waypoints, applies the configured
 * non-combat movement policy and reports arrival/failure with the authoritative request ID.
 * Service helicopters fly a normal MOVE route, then invoke the shared improved-landing controller
 * explicitly at the approach point. This avoids inventing a LAND waypoint type that Arma does not
 * support, while retaining an invisible-helipad landAt fallback.
 * Locality and authority: runs only where the AI driver group is local; server request IDs remain authoritative.
 *
 * Arguments: vehicle, service ID, request ID, phase, target ATL position, config HashMap and the
 * server-created invisible landing pad (helicopters only).
 * Return Value: Boolean - true when dispatched on the owning machine.
 * Example: [_heli,"RAVEN_1",12,"PICKUP",_lz,_config] call Waldo_fnc_TransportDispatchLocal;
 * Current caller: Waldo_fnc_TransportRequestServer owner-targeted remote execution.
 */
params ["_vehicle", "_id", "_requestId", "_phase", "_target", "_config", ["_landingPad", objNull, [objNull]]];
if (isNull _vehicle || {isNull driver _vehicle}) exitWith {false};
if (_vehicle getVariable ["Waldo_TransportService_RequestId", -1] != _requestId) exitWith {false};
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
    if (!isNull _landingPad) then {_vehicle landAt [_landingPad, "NONE"]};
    _vehicle land "NONE";
    _vehicle flyInHeight ((_config getOrDefault ["cruiseAltitude", 80]) max 20);
} else {
    _vehicle limitSpeed (_config getOrDefault ["groundSpeedLimit", 60]);
    // Prefer the engine's connected-road route when both the vehicle and resolved target are on a
    // road. Off-road requests retain normal terrain pathfinding instead of being pinned to roads.
    private _roadRoute = !((_vehicle nearRoads 30) isEqualTo []) && {!((_target nearRoads 20) isEqualTo [])};
    driver _vehicle forceFollowRoad _roadRoute;
};
private _standardImprovedLanding = _helicopter
    && {_config getOrDefault ["useImprovedLanding", true]}
    && {missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_Enable", true]};
// A landing waypoint can complete immediately while a helicopter is still parked. Give helicopters
// a real 75 metre departure MOVE leg before the destination approach waypoint. This is the same
// engine-safe sequence required for ordinary take-off-to-landing routes.
private _departureWaypoint = [];
if (_helicopter) then {
    private _departurePosition = _vehicle getPos [75, _vehicle getDir _target];
    _departurePosition set [2, 0];
    _departureWaypoint = _group addWaypoint [_departurePosition, -1];
    _departureWaypoint setWaypointType "MOVE";
    _departureWaypoint setWaypointBehaviour _movementBehaviour;
    _departureWaypoint setWaypointCombatMode "BLUE";
    _departureWaypoint setWaypointSpeed (_config getOrDefault ["speedMode", "FULL"]);
    _departureWaypoint setWaypointCompletionRadius 15;
};
// Radius -1 gives exact waypoint placement. Radius 0 may still be shifted by the engine.
private _waypoint = _group addWaypoint [_target, -1];
// LAND is a vehicle command, not a valid setWaypointType value. Keep the engine route as MOVE;
// the scheduled controller below hands the approach to improved landing when it enters range.
_waypoint setWaypointType "MOVE";
_waypoint setWaypointBehaviour _movementBehaviour;
_waypoint setWaypointCombatMode "BLUE";
_waypoint setWaypointSpeed (_config getOrDefault ["speedMode", "FULL"]);
_waypoint setWaypointCompletionRadius ((_config getOrDefault ["stopRadius", if (_helicopter) then {35} else {12}]) max 5);
_group setCurrentWaypoint (if (_helicopter) then {_departureWaypoint} else {_waypoint});
diag_log format ["[WMP TRANSPORT] Local dispatch service=%1 request=%2 phase=%3 target=%4 helicopter=%5 departure=%6 landing=%7 owner=%8", _id, _requestId, _phase, _target, _helicopter, if (_helicopter) then {_departureWaypoint select 1} else {-1}, _waypoint select 1, clientOwner];

[_vehicle, _id, _requestId, _phase, _target, _config, _helicopter, _landingPad, _waypoint] spawn {
    params ["_vehicle", "_id", "_requestId", "_phase", "_target", "_config", "_helicopter", "_landingPad", "_waypoint"];
    private _group = group driver _vehicle;
    private _stale = {_vehicle getVariable ["Waldo_TransportService_RequestId", -1] != _requestId};
    private _timeout = diag_tickTime + (missionNamespace getVariable ["Waldo_Transport_TravelTimeout", 900]);
    private _stopRadius = (_config getOrDefault ["stopRadius", if (_helicopter) then {35} else {12}]) max 5;
    if (_helicopter) then {
        private _standardImprovedLanding = _config getOrDefault ["useImprovedLanding", true]
            && {missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_Enable", true]};
        private _triggerDistance = if (_standardImprovedLanding && {!isNil "Waldo_fnc_ImprovedHelicopterLandingSetting"}) then {
            ((abs speed _vehicle) * ([_vehicle, "TriggerSpeedFactor", 4.2] call Waldo_fnc_ImprovedHelicopterLandingSetting))
                max ([_vehicle, "TriggerDistance", 500] call Waldo_fnc_ImprovedHelicopterLandingSetting)
        } else {220};
        private _landingWaypointIndex = _waypoint select 1;
        waitUntil {
            sleep 1;
            call _stale
            || {!local _group}
            || {!alive _vehicle}
            || {!alive driver _vehicle}
            || {currentWaypoint _group == _landingWaypointIndex && {_vehicle distance2D _target <= _triggerDistance}}
            || {diag_tickTime >= _timeout}
        };
        if (!(call _stale) && {local _group} && {alive _vehicle} && {alive driver _vehicle} && {currentWaypoint _group == _landingWaypointIndex} && {_vehicle distance2D _target <= _triggerDistance}) then {
            private _accepted = false;
            if (_standardImprovedLanding) then {
                _accepted = [
                    _vehicle,
                    _target,
                    "MOVE",
                    _landingWaypointIndex,
                    ""
                ] call Waldo_fnc_ImprovedHelicopterLandingExecuteLocal;
            };
            if (!_accepted && {!(call _stale)}) then {
                _accepted = if (isNull _landingPad) then {false} else {_vehicle landAt [_landingPad, "LAND"]};
                if (!_accepted) then {_vehicle land "LAND"};
            };
            if (_accepted && {_standardImprovedLanding}) then {
                waitUntil {
                    sleep 0.5;
                    call _stale
                    || {!local _group}
                    || {!alive _vehicle}
                    || {!alive driver _vehicle}
                    || {(isTouchingGround _vehicle || {getPosATL _vehicle select 2 < 1.5}) && {_vehicle distance2D _target <= _stopRadius}}
                    || {!(_vehicle getVariable ["Waldo_ImprovedHelicopterLanding_Active", false])}
                    || {diag_tickTime >= _timeout}
                };
                if (
                    !(call _stale)
                    && {alive _vehicle}
                    && {!isTouchingGround _vehicle}
                    && {!(_vehicle getVariable ["Waldo_ImprovedHelicopterLanding_Active", false])}
                ) then {
                    private _fallbackAccepted = if (isNull _landingPad) then {false} else {_vehicle landAt [_landingPad, "LAND"]};
                    if (!_fallbackAccepted) then {_vehicle land "LAND"};
                };
            };
        };
        waitUntil {sleep 1; call _stale || {!local _group} || {!alive _vehicle} || {!alive driver _vehicle} || {(isTouchingGround _vehicle || {getPosATL _vehicle select 2 < 1.5}) && {_vehicle distance2D _target <= _stopRadius}} || {diag_tickTime >= _timeout}};
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
    private _arrived = alive _vehicle && {alive driver _vehicle} && {_vehicle distance2D _target <= _stopRadius};
    [_id, _requestId, _phase, if (_arrived) then {"ARRIVED"} else {"FAILED"}] remoteExecCall ["Waldo_fnc_TransportReportServer", 2];
};
true

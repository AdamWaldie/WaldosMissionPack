/*
 * Author: WaldoTheWarfighter, Val
 * Executes one validated transport movement on the machine currently owning the AI driver group.
 * It creates only local control state, clears only that group's waypoints, applies the configured
 * non-combat movement policy and reports arrival/failure with the authoritative request ID.
 * Service helicopters use an exclusive invisible-helipad/landAt controller so the global improved
 * landing feature cannot fight the taxi lifecycle.
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
private _group = group driver _vehicle;
if (!local _group) exitWith {
    [_vehicle, _id, _requestId, _phase, _target, _config, _landingPad] remoteExecCall ["Waldo_fnc_TransportDispatchLocal", groupOwner _group];
    true
};
for "_i" from ((count waypoints _group) - 1) to 0 step -1 do {deleteWaypoint [_group, _i]};
_group setBehaviourStrong (_config getOrDefault ["behaviour", "CARELESS"]);
_group setCombatMode "BLUE";
_group setSpeedMode (_config getOrDefault ["speedMode", "FULL"]);
// Stop orders persist across deleted/replaced waypoints. Release every crew member before each
// pickup, destination or RTB dispatch so a vehicle stopped in the prior phase can move again.
units _group doFollow leader _group;
_vehicle engineOn true;
private _helicopter = _vehicle isKindOf "Helicopter";
if (_helicopter) then {
    if (_vehicle getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]) then {
        [_vehicle, false, ""] call Waldo_fnc_ImprovedHelicopterLandingRestoreLocal;
    };
    if (!isNull _landingPad) then {_vehicle landAt [_landingPad, "NONE"]};
    _vehicle land "NONE";
    _vehicle flyInHeight ((_config getOrDefault ["cruiseAltitude", 80]) max 20);
} else {
    _vehicle limitSpeed (_config getOrDefault ["groundSpeedLimit", 60]);
};
// Radius -1 gives exact waypoint placement. Radius 0 may still be shifted by the engine.
private _waypoint = _group addWaypoint [ATLToASL _target, -1];
_waypoint setWaypointType "MOVE";
_waypoint setWaypointBehaviour (_config getOrDefault ["behaviour", "CARELESS"]);
_waypoint setWaypointCombatMode "BLUE";
_waypoint setWaypointSpeed (_config getOrDefault ["speedMode", "FULL"]);
_waypoint setWaypointCompletionRadius ((_config getOrDefault ["stopRadius", if (_helicopter) then {35} else {12}]) max 5);
_group setCurrentWaypoint _waypoint;
if (!_helicopter) then {driver _vehicle doMove _target};
diag_log format ["[WMP TRANSPORT] Local dispatch service=%1 request=%2 phase=%3 target=%4 helicopter=%5 owner=%6", _id, _requestId, _phase, _target, _helicopter, clientOwner];

[_vehicle, _id, _requestId, _phase, _target, _config, _helicopter, _landingPad, _waypoint] spawn {
    params ["_vehicle", "_id", "_requestId", "_phase", "_target", "_config", "_helicopter", "_landingPad", "_waypoint"];
    private _group = group driver _vehicle;
    private _timeout = diag_tickTime + (missionNamespace getVariable ["Waldo_Transport_TravelTimeout", 900]);
    private _stopRadius = (_config getOrDefault ["stopRadius", if (_helicopter) then {35} else {12}]) max 5;
    if (_helicopter) then {
        waitUntil {sleep 1; !local _group || {!alive _vehicle} || {!alive driver _vehicle} || {_vehicle distance2D _target <= 220} || {diag_tickTime >= _timeout}};
        if (local _group && {alive _vehicle} && {alive driver _vehicle} && {_vehicle distance2D _target <= 220}) then {
            private _accepted = if (isNull _landingPad) then {false} else {_vehicle landAt [_landingPad, "LAND"]};
            if (!_accepted) then {_vehicle land "LAND"};
        };
        waitUntil {sleep 1; !local _group || {!alive _vehicle} || {!alive driver _vehicle} || {(isTouchingGround _vehicle || {getPosATL _vehicle select 2 < 1.5}) && {_vehicle distance2D _target <= _stopRadius}} || {diag_tickTime >= _timeout}};
    } else {
        private _bestDistance = _vehicle distance2D _target;
        private _lastProgress = diag_tickTime;
        private _retrySeconds = _config getOrDefault ["pathRetrySeconds", 25];
        private _retriesRemaining = _config getOrDefault ["pathRetryLimit", 3];
        waitUntil {
            sleep 1;
            private _distance = _vehicle distance2D _target;
            if (_distance < (_bestDistance - 5)) then {_bestDistance = _distance; _lastProgress = diag_tickTime};
            if (diag_tickTime - _lastProgress >= _retrySeconds && {_retriesRemaining > 0} && {alive driver _vehicle} && {local _group}) then {
                units _group doFollow leader _group;
                _group setCurrentWaypoint _waypoint;
                driver _vehicle doMove _target;
                _retriesRemaining = _retriesRemaining - 1;
                _lastProgress = diag_tickTime;
                diag_log format ["[WMP TRANSPORT] Reissued ground path service=%1 request=%2 remaining=%3 distance=%4", _id, _requestId, _retriesRemaining, round _distance];
            };
            !local _group || {!alive _vehicle} || {!alive driver _vehicle} || {_distance <= _stopRadius} || {diag_tickTime >= _timeout}
        };
        if (alive _vehicle && {_vehicle distance2D _target <= _stopRadius}) then {doStop driver _vehicle};
    };
    if (!local _group) exitWith {[_vehicle, _id, _requestId, _phase, _target, _config, _landingPad] remoteExecCall ["Waldo_fnc_TransportDispatchLocal", groupOwner _group]};
    private _arrived = alive _vehicle && {alive driver _vehicle} && {_vehicle distance2D _target <= _stopRadius};
    [_id, _requestId, _phase, if (_arrived) then {"ARRIVED"} else {"FAILED"}] remoteExecCall ["Waldo_fnc_TransportReportServer", 2];
};
true

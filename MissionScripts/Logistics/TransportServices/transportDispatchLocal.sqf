/*
 * Author: WaldoTheWarfighter, Val
 * Executes one validated transport movement on the machine currently owning the AI driver group.
 * It creates only local control state, clears only that group's waypoints, applies the configured
 * non-combat movement policy and reports arrival/failure with the authoritative request ID.
 * Helicopters use landing waypoints compatible with WMP improved helicopter landing.
 * Locality and authority: runs only where the AI driver group is local; server request IDs remain authoritative.
 *
 * Arguments: vehicle, service ID, request ID, phase, target ATL position and config HashMap.
 * Return Value: Boolean - true when dispatched on the owning machine.
 * Example: [_heli,"RAVEN_1",12,"PICKUP",_lz,_config] call Waldo_fnc_TransportDispatchLocal;
 * Current caller: Waldo_fnc_TransportRequestServer owner-targeted remote execution.
 */
params ["_vehicle", "_id", "_requestId", "_phase", "_target", "_config"];
if (isNull _vehicle || {isNull driver _vehicle}) exitWith {false};
private _group = group driver _vehicle;
if (!local _group) exitWith {
    [_vehicle, _id, _requestId, _phase, _target, _config] remoteExecCall ["Waldo_fnc_TransportDispatchLocal", groupOwner _group];
    true
};
for "_i" from ((count waypoints _group) - 1) to 0 step -1 do {deleteWaypoint [_group, _i]};
_group setBehaviourStrong (_config getOrDefault ["behaviour", "CARELESS"]);
_group setCombatMode "BLUE";
_group setSpeedMode (_config getOrDefault ["speedMode", "FULL"]);
_vehicle engineOn true;
private _helicopter = _vehicle isKindOf "Helicopter";
if (_helicopter) then {_vehicle flyInHeight ((_config getOrDefault ["cruiseAltitude", 80]) max 20)};
private _waypoint = _group addWaypoint [_target, 0];
_waypoint setWaypointType (if (_helicopter) then {"TR UNLOAD"} else {"MOVE"});
_waypoint setWaypointBehaviour (_config getOrDefault ["behaviour", "CARELESS"]);
_waypoint setWaypointCombatMode "BLUE";
_waypoint setWaypointSpeed (_config getOrDefault ["speedMode", "FULL"]);

[_vehicle, _id, _requestId, _phase, _target, _config, _helicopter] spawn {
    params ["_vehicle", "_id", "_requestId", "_phase", "_target", "_config", "_helicopter"];
    private _group = group driver _vehicle;
    private _timeout = diag_tickTime + (missionNamespace getVariable ["Waldo_Transport_TravelTimeout", 900]);
    private _stopRadius = (_config getOrDefault ["stopRadius", if (_helicopter) then {35} else {12}]) max 5;
    if (_helicopter) then {
        waitUntil {sleep 1; !local _group || {!alive _vehicle} || {!alive driver _vehicle} || {_vehicle distance2D _target <= 220} || {diag_tickTime >= _timeout}};
        if (!local _group) exitWith {};
        if (alive _vehicle && {alive driver _vehicle} && {_vehicle distance2D _target <= 220}) then {_vehicle land "LAND"};
        waitUntil {sleep 1; !local _group || {!alive _vehicle} || {!alive driver _vehicle} || {(isTouchingGround _vehicle || {getPosATL _vehicle select 2 < 1.5}) && {_vehicle distance2D _target <= _stopRadius * 2}} || {diag_tickTime >= _timeout}};
    } else {
        waitUntil {sleep 1; !local _group || {!alive _vehicle} || {!alive driver _vehicle} || {_vehicle distance2D _target <= _stopRadius} || {diag_tickTime >= _timeout}};
        if (alive _vehicle && {_vehicle distance2D _target <= _stopRadius}) then {doStop driver _vehicle};
    };
    if (!local _group) exitWith {[_vehicle, _id, _requestId, _phase, _target, _config] remoteExecCall ["Waldo_fnc_TransportDispatchLocal", groupOwner _group]};
    private _arrived = alive _vehicle && {alive driver _vehicle} && {_vehicle distance2D _target <= (_stopRadius * (if (_helicopter) then {2} else {1}))};
    [_id, _requestId, _phase, if (_arrived) then {"ARRIVED"} else {"FAILED"}] remoteExecCall ["Waldo_fnc_TransportReportServer", 2];
};
true

/*
 * Author: WaldoTheWarfighter
 * Replaces a group's current route with a bounded cyclic patrol around a centre.
 *
 * Simple pathing creates two movement points and a cycle; standard pathing creates four varied
 * points. The group's synthetic creation waypoints are removed, pathing is re-enabled and the
 * first generated waypoint is made current explicitly. Behaviour, speed and an optional formation
 * pool are applied immediately and to every waypoint. Aircraft receive their requested flight
 * radius while ground groups stay inside the AO.
 * Current caller: DynamicAOCreate for infantry, vehicles, civilians and air patrols.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: centre <ARRAY>
 * 2: radius <NUMBER>
 * 3: simple pathing <BOOL>
 * 4: behaviour <STRING> (default "AWARE")
 * 5: speed mode <STRING> (default "NORMAL")
 * 6: formation pool <ARRAY> (default []; one formation is selected for the complete route)
 *
 * Return Value:
 * Group
 *
 * Example:
 * [_group, _centre, 500, false, "SAFE", "LIMITED", ["COLUMN", "STAG COLUMN", "WEDGE"]]
 * call Waldo_fnc_DynamicAOAddPatrolWaypoints;
 */
params [
    "_group", "_centre", ["_radius", 500, [0]], ["_simple", false, [true]],
    ["_behaviour", "AWARE", [""]], ["_speed", "NORMAL", [""]], ["_formations", [], [[]]]
];
if (isNull _group) exitWith {_group};
if (!local _group) exitWith {
    diag_log format ["[WMP DYNAMIC AO] Refused to route non-local group %1 on owner %2.", _group, groupOwner _group];
    _group
};

// createGroup/createUnit leave completed synthetic waypoints behind. Appending a patrol does not
// reliably advance every newly created group onto it, so replace the route and activate it here.
private _existingWaypoints = waypoints _group;
for "_index" from ((count _existingWaypoints) - 1) to 0 step -1 do {
    deleteWaypoint (_existingWaypoints select _index);
};
{
    _x enableAI "PATH";
    _x enableAI "MOVE";
    if (_x != leader _group) then {_x doFollow leader _group};
} forEach units _group;
_group setBehaviour _behaviour;
_group setSpeedMode _speed;
private _formation = if (count _formations > 0) then {selectRandom _formations} else {""};
if (_formation != "") then {_group setFormation _formation};

private _count = if (_simple) then {2} else {4};
private _offset = random 360;
private _firstWaypoint = [];
for "_index" from 0 to (_count - 1) do {
    private _distance = _radius * (if (_simple) then {0.7} else {0.45 + random 0.45});
    private _position = _centre getPos [_distance, _offset + (_index * (360 / _count))];
    private _waypoint = _group addWaypoint [_position, 0];
    _waypoint setWaypointType "MOVE";
    _waypoint setWaypointBehaviour _behaviour;
    _waypoint setWaypointSpeed _speed;
    if (_formation != "") then {_waypoint setWaypointFormation _formation};
    _waypoint setWaypointCompletionRadius ((_radius * 0.08) max 15);
    if (_index == 0) then {_firstWaypoint = _waypoint};
};
private _cycle = _group addWaypoint [_centre, 0];
_cycle setWaypointType "CYCLE";
if (count _firstWaypoint > 0) then {_group setCurrentWaypoint _firstWaypoint};
diag_log format [
    "[WMP DYNAMIC AO] Route armed group=%1 local=%2 waypoints=%3 current=%4 units=%5 behaviour=%6 speed=%7 formation=%8.",
    _group, local _group, count waypoints _group, currentWaypoint _group, count units _group,
    _behaviour, _speed, _formation
];
_group

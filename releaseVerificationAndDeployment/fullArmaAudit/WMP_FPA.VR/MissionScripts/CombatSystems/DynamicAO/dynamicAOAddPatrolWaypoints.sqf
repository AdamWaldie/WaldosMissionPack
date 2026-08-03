/*
 * Author: WaldoTheWarfighter
 * Adds a bounded cyclic patrol route around a centre to an AI group.
 *
 * Simple pathing creates two movement points and a cycle; standard pathing creates four varied
 * points. Aircraft receive their requested flight radius while ground groups stay inside the AO.
 * Current caller: DynamicAOCreate for infantry, vehicles, civilians and air patrols.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: centre <ARRAY>
 * 2: radius <NUMBER>
 * 3: simple pathing <BOOL>
 * 4: behaviour <STRING> (default "AWARE")
 *
 * Return Value:
 * Group
 *
 * Example:
 * [_group, _centre, 500, false] call Waldo_fnc_DynamicAOAddPatrolWaypoints;
 */
params ["_group", "_centre", ["_radius", 500, [0]], ["_simple", false, [true]], ["_behaviour", "AWARE", [""]]];
if (isNull _group) exitWith {_group};
private _count = if (_simple) then {2} else {4};
private _offset = random 360;
for "_index" from 0 to (_count - 1) do {
    private _distance = _radius * (if (_simple) then {0.7} else {0.45 + random 0.45});
    private _position = _centre getPos [_distance, _offset + (_index * (360 / _count))];
    private _waypoint = _group addWaypoint [_position, 0];
    _waypoint setWaypointType "MOVE";
    _waypoint setWaypointBehaviour _behaviour;
    _waypoint setWaypointCompletionRadius ((_radius * 0.08) max 15);
};
private _cycle = _group addWaypoint [_centre, 0];
_cycle setWaypointType "CYCLE";
_group

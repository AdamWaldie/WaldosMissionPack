/*
 * Author: Waldo
 * Applies loiter routing where the aircraft and pilot group are local.
 * Arguments: aircraft, position, altitude, radius, direction, behaviour, combat mode
 * Return Value: Boolean
 */

params ["_aircraft", "_position", "_altitude", "_radius", "_direction", "_behaviour", "_combatMode"];
if (isNull _aircraft || {!local _aircraft} || {isNull driver _aircraft}) exitWith {false};
private _group = group driver _aircraft;
_group setBehaviourStrong _behaviour;
_group setCombatMode _combatMode;
for "_index" from ((count waypoints _group) - 1) to 0 step -1 do {deleteWaypoint [_group, _index]};
_aircraft flyInHeight _altitude;
private _waypoint = _group addWaypoint [_position, 0];
_waypoint setWaypointType "LOITER";
_waypoint setWaypointLoiterRadius _radius;
_waypoint setWaypointLoiterType _direction;
true

/*
 * Author: WaldoTheWarfighter
 * Applies loiter routing where the aircraft and pilot group are local.
 * Locality and authority: Runs on the current aircraft owner; waypoint and flight commands
 * require local aircraft/group authority after server validation of the orbit request.
 * Repeat/JIP: Replaces the pilot group's prior waypoints on every accepted orbit update.
 * Joining clients receive the published orbit state, not a local waypoint replay.
 * Arguments: aircraft, position, altitude, radius, direction, behaviour, combat mode
 * Return Value: Boolean
 * Current callers: Waldo_fnc_GunshipSetOrbit and GunshipServerHandle on the aircraft owner.
 * Example: [_aircraft, _centre, 600, 800, "CIRCLE_L", "AWARE", "YELLOW"] call Waldo_fnc_GunshipApplyOrbitLocal;
 * Result: The pilot group loiters at the requested centre, altitude and radius.
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

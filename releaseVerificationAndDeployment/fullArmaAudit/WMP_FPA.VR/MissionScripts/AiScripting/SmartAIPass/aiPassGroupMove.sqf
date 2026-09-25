/*
 * Author: WaldoTheWarfighter
 * Moves a whole group by inserting one temporary MOVE waypoint ahead of its current waypoint.
 *
 * The audited mods used group `move` (which makes the engine ignore active waypoints) or ordered the
 * leader himself with `doMove` (a plausible cause of squads freezing). An inserted waypoint is
 * engine-native: the group moves in formation, and when it completes the waypoint it carries on with
 * its own patrol or task waypoints. Pass waypoints are tagged "WMP AI PASS" in their description, so
 * Waldo_fnc_AIPassGroupMoveClear can remove them without tracking indices. Only one pass waypoint
 * exists per group at a time.
 * Locality and authority: call where the group is local (setCurrentWaypoint is local-argument).
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: position <ARRAY> - ATL destination
 * 2: completion radius <NUMBER> - metres (optional, default: 25)
 * 3: type <STRING> - waypoint type, MOVE or SAD (optional, default: "MOVE")
 *
 * Return Value:
 * Array - the waypoint [group, index]
 *
 * Example:
 * [_group, _rallyPoint] call Waldo_fnc_AIPassGroupMove;
 * Result: the group moves to the rally point, then resumes its own waypoints.
 *
 * Current callers: retreat, reinforcement, coordinated assault, investigation, vehicle withdrawal and
 * standoff, and shoot-and-scoot.
 */

params [["_group", grpNull, [grpNull]], ["_position", [], [[]]], ["_radius", 25, [0]], ["_type", "MOVE", [""]]];
[_group] call Waldo_fnc_AIPassGroupMoveClear;
private _waypoint = _group addWaypoint [_position, 0, currentWaypoint _group];
_waypoint setWaypointType _type;
_waypoint setWaypointCompletionRadius _radius;
_waypoint setWaypointDescription "WMP AI PASS";
_group setCurrentWaypoint _waypoint;
_waypoint

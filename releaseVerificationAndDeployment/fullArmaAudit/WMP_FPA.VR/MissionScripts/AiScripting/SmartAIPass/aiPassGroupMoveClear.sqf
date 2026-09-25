/*
 * Author: WaldoTheWarfighter
 * Removes any temporary waypoint the Smart AI Pass inserted for a group.
 *
 * Deleting the current waypoint makes the engine continue with the group's next waypoint, so the
 * group's own orders resume. Waypoints are found by their "WMP AI PASS" description, from the end of
 * the list so indices stay valid while deleting.
 * Locality and authority: callable anywhere (deleteWaypoint is global); normally called by the owner.
 *
 * Arguments:
 * 0: group <GROUP>
 *
 * Return Value:
 * Number - waypoints removed
 *
 * Example:
 * [_group] call Waldo_fnc_AIPassGroupMoveClear;
 * Result: the group goes back to its own waypoints.
 *
 * Current callers: Waldo_fnc_AIPassGroupMove, Waldo_fnc_AIPassGroupTick and Waldo_fnc_AIPassReleaseGroup.
 */

params [["_group", grpNull, [grpNull]]];
if (isNull _group) exitWith {0};
private _removed = 0;
for "_index" from (count waypoints _group - 1) to 0 step -1 do {
    if (waypointDescription [_group, _index] == "WMP AI PASS") then {
        deleteWaypoint [_group, _index];
        _removed = _removed + 1;
    };
};
_removed

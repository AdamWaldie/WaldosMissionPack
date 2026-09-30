/*
 * Author: WaldoTheWarfighter
 * Marks an AI group as under Zeus control so the Smart AI Pass steps back from it.
 *
 * Called on the curator's own machine by the handlers Waldo_fnc_CortexZeusWatchLocal installs. Any
 * control interaction holds it for Waldo_AIPass_ZeusHoldSeconds (default 120): opening attributes,
 * moving a unit, or editing its waypoints. Plain selection does not cancel behaviour, allowing
 * curators to inspect active squads. Dependent jobs stop issuing commands once the hold reaches
 * their owner. Assignment cleanup occurs on the next owner scheduler tick. A waypoint placed or
 * moved by Zeus (including the DESTROY
 * waypoint created by designating a target) also holds the group until it has finished every waypoint
 * Zeus gave it.
 * The hold is published as a random token plus a duration, not an absolute time, so the owning
 * machine times it with its own clock. Repeated attribute/control marks of the same group are sent at most once
 * every 10 s. Waypoint changes are always sent. Nothing is sent while the pass is disabled or for
 * groups containing players.
 * Locality and authority: runs on the curator's client; publishes two group variables.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: waypoints <BOOL> - true when Zeus changed the group's waypoints (optional, default: false)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_group, true] call Waldo_fnc_CortexZeusMark;
 * Result: the group follows the Zeus waypoint without the pass interfering until it is complete.
 *
 * Current caller: curator event handlers installed by Waldo_fnc_CortexZeusWatchLocal.
 */

params [["_group", grpNull, [grpNull]], ["_waypoints", false, [false]]];
if (isNull _group || {!(missionNamespace getVariable ["Waldo_AIPass_Enable", false])}) exitWith {};
if ((units _group) findIf {isPlayer _x} >= 0 || {(units _group) findIf {alive _x} < 0}) exitWith {};
if (!_waypoints && {time - (_group getVariable ["Waldo_AIPass_ZeusMarkedAt", -1e6]) < 10}) exitWith {};
_group setVariable ["Waldo_AIPass_ZeusMarkedAt", time];
_group setVariable ["Waldo_AIPass_ZeusHold", [random 1e6, missionNamespace getVariable ["Waldo_AIPass_ZeusHoldSeconds", 120]], true];
if (_waypoints && {!(_group getVariable ["Waldo_AIPass_ZeusWaypoints", false])}) then {
    _group setVariable ["Waldo_AIPass_ZeusWaypoints", true, true];
};

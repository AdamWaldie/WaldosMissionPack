/*
 * Author: WaldoTheWarfighter
 * Marks an AI group as under Zeus control so the Smart AI Pass steps back from it.
 *
 * Called on the curator's own machine by the handlers Waldo_fnc_CortexZeusWatchLocal installs. Any
 * control interaction holds it for Waldo_AIPass_ZeusHoldSeconds (default 120): opening attributes,
 * moving a unit, or editing its waypoints. Plain selection does not cancel behaviour, allowing
 * curators to inspect active squads. Dependent jobs stop issuing commands once the hold reaches
 * their owner. The marker immediately asks the current group owner to release Cortex state, avoiding
 * a scheduler-delay race with the curator's replacement order. A waypoint event snapshots the
 * selected waypoint's position, behaviour, speed and combat mode beside the same hold token. Finite controllers
 * can therefore hand over to the order Zeus actually selected even if Arma changes currentWaypoint
 * while their owner-local cleanup is running. A waypoint placed or moved by Zeus (including the DESTROY
 * waypoint created by designating a target) also holds the group until it has finished every waypoint
 * Zeus gave it.
 * A mark also revokes any expiring combined-arms role before dispatching cleanup. This prevents a
 * stale ground-fire target or aircraft role token surviving beside the curator's replacement order;
 * the aircraft controller observes the hold on its next half-second step and never restores its old route.
 * The hold is published as a random token plus a duration, not an absolute time, so the owning
 * machine times it with its own clock. Repeated attribute/control marks of the same group are sent at most once
 * every 10 s. Waypoint changes are always sent. Nothing is sent while the pass is disabled or for
 * groups containing players.
 * Locality and authority: runs on the curator's client; publishes the hold, waypoint flag and a
 * token-bound order snapshot. The group owner consumes the snapshot but never edits it.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: waypoints <BOOL> - true when Zeus changed the group's waypoints (optional, default: false)
 * 2: waypoint index <NUMBER> - exact curator event waypoint, or -1 to use currentWaypoint
 *    (optional, default: -1)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_group, true, _waypointID] call Waldo_fnc_CortexZeusMark;
 * Result: the group follows the Zeus waypoint without the pass interfering until it is complete.
 *
 * Current caller: curator event handlers installed by Waldo_fnc_CortexZeusWatchLocal.
 */

params [["_group", grpNull, [grpNull]], ["_waypoints", false, [false]], ["_waypointIndex",-1,[0]]];
if (isNull _group || {!(missionNamespace getVariable ["Waldo_AIPass_Enable", false])}) exitWith {};
if ((units _group) findIf {isPlayer _x} >= 0 || {(units _group) findIf {alive _x} < 0}) exitWith {};
if (!_waypoints && {time - (_group getVariable ["Waldo_AIPass_ZeusMarkedAt", -1e6]) < 10}) exitWith {};
_group setVariable ["Waldo_AIPass_ZeusMarkedAt", time];
private _hold=[random 1e6, missionNamespace getVariable ["Waldo_AIPass_ZeusHoldSeconds", 120]];
_group setVariable ["Waldo_AIPass_ZeusHold", _hold, true];
if (_waypoints) then {
    if (_waypointIndex < 0) then {_waypointIndex=currentWaypoint _group};
    private _groupWaypoints=waypoints _group;
    if (_waypointIndex >= 0 && {_waypointIndex < count _groupWaypoints}) then {
        private _waypoint=[_group,_waypointIndex];
        // This is immutable evidence from the curator event boundary. Do not derive it later from
        // currentWaypoint: the engine may make a former scripted waypoint current during cleanup.
        _group setVariable ["Waldo_Cortex_ZeusOrderSnapshot",[
            _hold select 0,
            waypointPosition _waypoint,
            waypointBehaviour _waypoint,
            waypointSpeed _waypoint,
            waypointType _waypoint,
            _waypointIndex,
            waypointCombatMode _waypoint
        ],true];
    } else {
        _group setVariable ["Waldo_Cortex_ZeusOrderSnapshot",nil,true];
    };
} else {
    // A later attributes/object edit supersedes any earlier waypoint event. Clearing the snapshot
    // prevents an old route being reused during this newer, non-waypoint Zeus takeover.
    _group setVariable ["Waldo_Cortex_ZeusOrderSnapshot",nil,true];
};
if (_waypoints && {!(_group getVariable ["Waldo_AIPass_ZeusWaypoints", false])}) then {
    _group setVariable ["Waldo_AIPass_ZeusWaypoints", true, true];
};
private _combinedRole = _group getVariable ["Waldo_Cortex_CombinedRole", []];
if (_combinedRole isNotEqualTo []) then {
    _group setVariable ["Waldo_Cortex_CombinedResult", [
        _combinedRole param [0,""], _combinedRole param [4,""], "ZEUS_TAKEOVER", serverTime,
        _combinedRole param [2,objNull]
    ], true];
    _group setVariable ["Waldo_Cortex_CombinedRole", nil, true];
    _group setVariable ["Waldo_Cortex_CombinedApplied", nil, true];
};
if ((_group getVariable ["Waldo_Cortex_CombinedOpportunity", []]) isNotEqualTo []) then {
    _group setVariable ["Waldo_Cortex_CombinedOpportunity", nil, true];
};
// Publish the hold before cleanup so CortexReleaseGroup recognises an external takeover and
// restores only Cortex-owned state without replacing the curator's movement, behaviour or speed.
if (local _group) then {
    [_group,false,"ZEUS_TAKEOVER"] call Waldo_fnc_CortexReleaseGroup;
} else {
    [_group,false,"ZEUS_TAKEOVER"] remoteExecCall ["Waldo_fnc_CortexReleaseGroup",groupOwner _group];
};

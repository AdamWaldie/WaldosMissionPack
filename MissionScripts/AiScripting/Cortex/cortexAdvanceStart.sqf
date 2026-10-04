/*
 * Author: WaldoTheWarfighter
 * Starts a bounding advance: a squad under fire that still has somewhere to go pushes an element
 * forward in covered bounds instead of stalling.
 *
 * Uses bounded fire-team movement so that it cannot freeze or
 * undo itself. The squad must have been in CONTACT for Waldo_AIPass_Advance_MinContactSeconds, its
 * current waypoint (MOVE, SAD or DESTROY, not a pass waypoint) must be more than 80 m away, or a squad
 * with no active waypoint must have fresh enemy knowledge that provides a finite contact objective.
 * Active HOLD, GUARD, SENTRY and other authored waypoint types are never replaced. The nearest known
 * enemy must be at least 60 m away, morale must be STEADY and no drill may be running.
 * Waldo_fnc_CortexTacticalStart prefers this action for a live authored forward order and calls this
 * deterministic viability/start function. A bounded avenue selector compares the
 * direct route with four offset two-leg routes and samples screening once when the drill starts.
 * Two elements advance successively: riflemen
 * move first while the leader/support element covers, then hold while that element closes up.
 * Both elements must physically arrive before the next bound. Movers retain firing permission while the other element covers.
 * Actors completing a short grenade-evasion or anti-armour relocation lease are omitted from both
 * elements rather than having their destination replaced.
 * Group attack assignment remains enabled so the covering element can acquire and share targets;
 * only the current movers receive short, owned pursuit-feature leases in CortexFlankStep.
 * This is successive bounding overwatch, not alternating leapfrog or multi-squad coordination.
 * Locality and authority: call where the group is local.
 *
 * Each start gives its queued step a unique drill token.
 * Repeat/JIP: a running drill, shared movement lease or cooldown refuses duplicate starts; owner
 * migration retires local jobs. A rolling TACTICAL_DRILL lease makes direct fire-team movement
 * visible to reinforcement, vehicle and artillery behaviours until CortexFlankEnd releases it.
 * The drill heartbeat lets GroupTick restore every owned engine setting if its scheduler job stalls.
 * The latest changed refusal reason is public for diagnostics and is cleared when a drill starts;
 * repeated start checks do not rebroadcast an unchanged reason.
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: enemies <ARRAY> - from Waldo_fnc_CortexKnowledge
 *
 * Return Value:
 * Boolean - true when an advance started
 *
 * Example:
 * [_group, _state, _enemies] call Waldo_fnc_CortexAdvanceStart;
 * Result: a pinned squad advances two elements successively towards its authored or fresh-contact objective.
 *
 * Support integration: active reinforcement/assault responders decline new drills until released.
 * Current caller: Waldo_fnc_CortexTacticalStart.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
private _refuse={
    params ["_reason",["_detail",[]]];
    private _previous=_group getVariable ["Waldo_Cortex_AdvanceRefusal",[]];
    if ((_previous param [0,""]) != _reason) then {
        _group setVariable ["Waldo_Cortex_AdvanceRefusal",[_reason,serverTime,_detail],true];
    };
    false
};
// A live support assignment owns group movement until release; do not split its
// responders into a competing local drill when they acquire contact.
if (_state getOrDefault ["responding", false] || {_state getOrDefault ["assaulting", false]}) exitWith {["SUPPORT_OWNS_MOVEMENT"] call _refuse};
private _movementLease = _state getOrDefault ["movementLease",[]];
if (count _movementLease == 2 && {time < (_movementLease select 1)}) exitWith {["MOVEMENT_LEASE",_movementLease] call _refuse};
if (count (_state getOrDefault ["drill", createHashMap]) > 0) exitWith {["DRILL_ACTIVE"] call _refuse};
if ([_state, "advance"] call Waldo_fnc_CortexCooldown) exitWith {["COOLDOWN"] call _refuse};
if ((_state getOrDefault ["moraleState", "STEADY"]) != "STEADY") exitWith {["MORALE",[_state getOrDefault ["moraleState","UNKNOWN"]]] call _refuse};
private _contactAge=time-(_state getOrDefault ["phaseStart",time]);
private _minimumContact=missionNamespace getVariable ["Waldo_AIPass_Advance_MinContactSeconds", 5];
if (_contactAge < _minimumContact) exitWith {["CONTACT_DELAY",[_contactAge,_minimumContact]] call _refuse};
private _leader = leader _group;
if (vehicle _leader != _leader) exitWith {["LEADER_MOUNTED"] call _refuse};
if (_enemies isEqualTo []) exitWith {["NO_TARGET"] call _refuse};
if (((_enemies select 0) select 3) < 60) exitWith {["TARGET_TOO_CLOSE",[(_enemies select 0) select 3]] call _refuse};
private _index = currentWaypoint _group;
private _hasAuthoredObjective = _index < count waypoints _group;
if (_hasAuthoredObjective && {
    waypointDescription [_group, _index] == "WMP AI PASS"
    || {!(waypointType [_group, _index] in ["MOVE", "SAD", "DESTROY"])}
}) exitWith {["AUTHORED_OBJECTIVE_TYPE",[waypointType [_group,_index],waypointDescription [_group,_index]]] call _refuse};
// A group whose ordinary movement order has completed should not become inert in a live firefight.
// Use only fresh engine knowledge and keep the objective inside this finite drill; do not manufacture
// a persistent waypoint that would outlive contact or compete with a later Zeus order.
if (!_hasAuthoredObjective && {((_enemies select 0) select 2) > 10}) exitWith {["STALE_CONTACT",[(_enemies select 0) select 2]] call _refuse};
private _objective = if (_hasAuthoredObjective) then {
    waypointPosition [_group, _index]
} else {
    (_enemies select 0) select 1
};
if (_leader distance2D _objective <= 80) exitWith {["OBJECTIVE_REACHED",[_leader distance2D _objective]] call _refuse};
private _onFoot = (units _group) select {
    private _actorMove = _x getVariable ["Waldo_Cortex_ActorMove",[]];
    [_x] call Waldo_fnc_CortexCombatEffective && {local _x} && {vehicle _x == _x}
        && {_x checkAIFeature "PATH"} && {_x checkAIFeature "MOVE"}
        && {count _actorMove != 3 || {time >= (_actorMove select 2)}}
};
private _riflemen = _onFoot select {_x != _leader && {!(([_x] call Waldo_fnc_CortexUnitRole) in ["MG", "AT", "LEADER"])}};
private _candidates = [];
{_candidates pushBack [_x distance2D _objective, _forEachIndex]} forEach _riflemen;
_candidates sort true;
private _size = ((floor (count _onFoot / 2)) min 5) min count _candidates;
if (_size < 2) exitWith {[_state, "advance", 30] call Waldo_fnc_CortexCooldown; ["NO_MANOEUVRE_ELEMENT",[count _onFoot,count _riflemen]] call _refuse};
private _element = (_candidates select [0, _size]) apply {_riflemen select (_x select 1)};
private _coverElement = _onFoot - _element;
if (count _coverElement < 2) exitWith {["NO_COVER_ELEMENT",[count _coverElement]] call _refuse};
private _start = [0, 0, 0];
{_start = _start vectorAdd getPosATL _x} forEach _element;
_start = _start vectorMultiply (1 / count _element);
private _bound = (missionNamespace getVariable ["Waldo_AIPass_Flank_BoundDistance", 55]) max 15;
private _goal = _start getPos [((_start distance2D _objective) - 20) min (_bound * 3), _start getDir _objective];
private _routeDistance=_start distance2D _goal;
private _axis=_start getDir _goal;
private _midDistance=_routeDistance*0.55;
private _offset=((_routeDistance*0.25) max 20) min 55;
private _candidateRoutes=[[_goal]];
{
    private _screen=(_start getPos [_midDistance,_axis]) getPos [_offset,_axis+_x];
    _candidateRoutes pushBack [_screen,_goal];
} forEach [90,-90,55,-55];
private _legs=[_start,_candidateRoutes,(_enemies select 0) select 1,[],(_enemies select 0) select 0]
    call Waldo_fnc_CortexSelectAvenue;
if (_legs isEqualTo []) exitWith {[_state, "advance", 30] call Waldo_fnc_CortexCooldown; ["NO_SAFE_AVENUE",[_start,_objective]] call _refuse};
private _points = [_start, _legs, "FINAL", _group] call Waldo_fnc_CortexPlanRoute;
// Do not suppress the whole squad's attack assignment. CortexFlankStep protects only
// the current moving element while the paired element continues native engagement.
private _serial = (missionNamespace getVariable ["Waldo_Cortex_DrillSerial",0]) + 1;
missionNamespace setVariable ["Waldo_Cortex_DrillSerial",_serial];
private _token = format ["%1:%2",clientOwner,_serial];
_group setVariable ["Waldo_Cortex_DrillResult",[],true];
_group setVariable ["Waldo_Cortex_DrillFailure",[],true];
_group setVariable ["Waldo_Cortex_DrillReinforcements",[],true];
_state set ["drill", createHashMapFromArray [
    ["token",_token],["target",(_enemies select 0) select 0],
    ["teams",[_element,_coverElement]],["teamSizes",[count _element,count _coverElement]],["teamTurn",0],
    ["type", "ADVANCE"], ["units", _onFoot], ["desiredStrength",count _onFoot], ["points", _points], ["index", 0], ["stage", ""],
    ["enemyPos", (_enemies select 0) select 1], ["disabled", []], ["spots", []], ["started", time], ["lastStep",time],
    ["boundStart", time], ["pauseUntil", 0]
]];
if !([_group,"TACTICAL_DRILL",true,serverTime+90] call Waldo_fnc_CortexLambsLease) exitWith {
    _state deleteAt "drill";
    ["EXTERNAL_MOVEMENT_BUSY"] call _refuse
};
[_group,_state get "drill","START","ADVANCE_ACCEPTED"] call Waldo_fnc_CortexDrillSetStage;
_group setVariable ["Waldo_Cortex_AdvanceRefusal",nil,true];
// Direct fire-team bounds are a group movement owner even though they do not
// create a WMP waypoint. Other behaviours must wait until CortexFlankEnd releases it.
_state set ["movementLease",["TACTICAL_DRILL",time+90]];
[Waldo_fnc_CortexFlankStep, createHashMapFromArray [["group", _group],["drillToken",_token]], 0] call Waldo_fnc_CortexQueueJob;
if (missionNamespace getVariable ["Waldo_AIPass_Debug", false]) then {
    diag_log format ["[WMP CORTEX] %1 ADVANCE element=%2 points=%3", _group, count _element, count _points];
};
true

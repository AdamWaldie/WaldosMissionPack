/*
 * Author: WaldoTheWarfighter
 * Starts a bounding advance: a squad under fire that still has somewhere to go pushes an element
 * forward in covered bounds instead of stalling.
 *
 * From PROTOCOL's Combat Pairs and Smart Combat V2's bounding, rebuilt so that it cannot freeze or
 * undo itself. The squad must have been in CONTACT for Waldo_AIPass_Advance_MinContactSeconds, its
 * current waypoint (MOVE, SAD or DESTROY, not a pass waypoint) must be more than 80 m away, the nearest
 * known enemy must be at least 60 m away, morale must be STEADY, no drill may be running, and the
 * behaviour profile's advanceChance roll must succeed. Up to half the squad (riflemen, as for a flank)
 * bounds up to three bounds towards the waypoint through Waldo_fnc_AIPassFlankStep, with cover facing
 * the enemy and street crossings under smoke, while the leader, machine gunners and AT gunners
 * overwatch. The element then holds its ground until the rest of the squad, moving on its own
 * waypoint, closes up. Engine COMBAT movement still handles the rest of the squad.
 * Locality and authority: call where the group is local.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: enemies <ARRAY> - from Waldo_fnc_AIPassKnowledge
 *
 * Return Value:
 * Boolean - true when an advance started
 *
 * Example:
 * [_group, _state, _enemies] call Waldo_fnc_AIPassAdvanceStart;
 * Result: a pinned squad leapfrogs a fire team forward towards its objective.
 *
 * Current caller: Waldo_fnc_AIPassGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
if (count (_state getOrDefault ["drill", createHashMap]) > 0) exitWith {false};
if ([_state, "advance"] call Waldo_fnc_AIPassCooldown) exitWith {false};
if ((_state getOrDefault ["moraleState", "STEADY"]) != "STEADY") exitWith {false};
if (time - (_state getOrDefault ["phaseStart", time]) < (missionNamespace getVariable ["Waldo_AIPass_Advance_MinContactSeconds", 30])) exitWith {false};
private _leader = leader _group;
if (vehicle _leader != _leader) exitWith {false};
private _index = currentWaypoint _group;
if (_index >= count waypoints _group) exitWith {false};
if (waypointDescription [_group, _index] == "WMP AI PASS" || {!(waypointType [_group, _index] in ["MOVE", "SAD", "DESTROY"])}) exitWith {false};
private _objective = waypointPosition [_group, _index];
if (_leader distance2D _objective <= 80) exitWith {false};
if (_enemies isEqualTo [] || {((_enemies select 0) select 3) < 60}) exitWith {false};
if (random 1 > ([_group, "advanceChance"] call Waldo_fnc_AIPassProfile)) exitWith {
    [_state, "advance", 30] call Waldo_fnc_AIPassCooldown;
    false
};
private _onFoot = (units _group) select {alive _x && {local _x} && {vehicle _x == _x}};
private _riflemen = _onFoot select {_x != _leader && {!(([_x] call Waldo_fnc_AIPassUnitRole) in ["MG", "AT", "LEADER"])}};
private _candidates = [];
{_candidates pushBack [_x distance2D _objective, _forEachIndex]} forEach _riflemen;
_candidates sort true;
private _size = ((floor (count _onFoot / 2)) min 5) min count _candidates;
if (_size < 2) exitWith {[_state, "advance", 30] call Waldo_fnc_AIPassCooldown; false};
private _element = (_candidates select [0, _size]) apply {_riflemen select (_x select 1)};
private _start = [0, 0, 0];
{_start = _start vectorAdd getPosATL _x} forEach _element;
_start = _start vectorMultiply (1 / count _element);
private _bound = (missionNamespace getVariable ["Waldo_AIPass_Flank_BoundDistance", 40]) max 15;
private _goal = _start getPos [((_start distance2D _objective) - 20) min (_bound * 3), _start getDir _objective];
if (surfaceIsWater _goal) exitWith {[_state, "advance", 30] call Waldo_fnc_AIPassCooldown; false};
private _points = [_start, [_goal]] call Waldo_fnc_AIPassPlanRoute;
_state set ["drill", createHashMapFromArray [
    ["type", "ADVANCE"], ["units", _element], ["points", _points], ["index", 0], ["stage", "START"],
    ["enemyPos", (_enemies select 0) select 1], ["disabled", []], ["spots", []], ["started", time],
    ["boundStart", time], ["pauseUntil", 0]
]];
[Waldo_fnc_AIPassFlankStep, createHashMapFromArray [["group", _group]], 0] call Waldo_fnc_AIPassQueueJob;
if (missionNamespace getVariable ["Waldo_AIPass_Debug", false]) then {
    diag_log format ["[WMP AI PASS] %1 ADVANCE element=%2 points=%3", _group, count _element, count _points];
};
true

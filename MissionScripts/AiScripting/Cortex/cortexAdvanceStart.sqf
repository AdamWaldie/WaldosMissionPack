/*
 * Author: WaldoTheWarfighter
 * Starts a bounding advance: a squad under fire that still has somewhere to go pushes an element
 * forward in covered bounds instead of stalling.
 *
 * Uses bounded fire-team movement so that it cannot freeze or
 * undo itself. The squad must have been in CONTACT for Waldo_AIPass_Advance_MinContactSeconds, its
 * current waypoint (MOVE, SAD or DESTROY, not a pass waypoint) must be more than 80 m away, the nearest
 * known enemy must be at least 60 m away, morale must be STEADY, no drill may be running, and the
 * behaviour profile's advanceChance roll must succeed. Two elements advance successively: riflemen
 * move first while the leader/support element covers, then hold while that element closes up.
 * Both elements must physically arrive before the next bound. Movers retain firing permission while the other element covers.
 * Group attack assignment remains enabled so the covering element can acquire and share targets;
 * only the current movers receive short, owned pursuit-feature leases in CortexFlankStep.
 * This is successive bounding overwatch, not alternating leapfrog or multi-squad coordination.
 * Locality and authority: call where the group is local.
 *
 * Each start gives its queued step a unique drill token.
 * Repeat/JIP: a running drill or cooldown refuses duplicate starts; owner migration retires local jobs.
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
 * Result: a pinned squad advances two elements successively towards its objective.
 *
 * Support integration: active reinforcement/assault responders decline new drills until released.
 * Current caller: Waldo_fnc_CortexGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
// A live support assignment owns group movement until release; do not split its
// responders into a competing local drill when they acquire contact.
if (_state getOrDefault ["responding", false] || {_state getOrDefault ["assaulting", false]}) exitWith {false};
if (count (_state getOrDefault ["drill", createHashMap]) > 0) exitWith {false};
if ([_state, "advance"] call Waldo_fnc_CortexCooldown) exitWith {false};
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
if (random 1 >= ([_group, "advanceChance"] call Waldo_fnc_CortexProfile)) exitWith {
    [_state, "advance", 30] call Waldo_fnc_CortexCooldown;
    false
};
private _onFoot = (units _group) select {[_x] call Waldo_fnc_CortexCombatEffective && {local _x} && {vehicle _x == _x} && {_x checkAIFeature "PATH"} && {_x checkAIFeature "MOVE"}};
private _riflemen = _onFoot select {_x != _leader && {!(([_x] call Waldo_fnc_CortexUnitRole) in ["MG", "AT", "LEADER"])}};
private _candidates = [];
{_candidates pushBack [_x distance2D _objective, _forEachIndex]} forEach _riflemen;
_candidates sort true;
private _size = ((floor (count _onFoot / 2)) min 5) min count _candidates;
if (_size < 2) exitWith {[_state, "advance", 30] call Waldo_fnc_CortexCooldown; false};
private _element = (_candidates select [0, _size]) apply {_riflemen select (_x select 1)};
private _coverElement = _onFoot - _element;
if (count _coverElement < 2) exitWith {false};
private _start = [0, 0, 0];
{_start = _start vectorAdd getPosATL _x} forEach _element;
_start = _start vectorMultiply (1 / count _element);
private _bound = (missionNamespace getVariable ["Waldo_AIPass_Flank_BoundDistance", 40]) max 15;
private _goal = _start getPos [((_start distance2D _objective) - 20) min (_bound * 3), _start getDir _objective];
if (surfaceIsWater _goal) exitWith {[_state, "advance", 30] call Waldo_fnc_CortexCooldown; false};
private _points = [_start, [_goal], "FINAL", _group] call Waldo_fnc_CortexPlanRoute;
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
    ["type", "ADVANCE"], ["units", _onFoot], ["desiredStrength",count _onFoot], ["points", _points], ["index", 0], ["stage", "START"],
    ["enemyPos", (_enemies select 0) select 1], ["disabled", []], ["spots", []], ["started", time],
    ["boundStart", time], ["pauseUntil", 0]
]];
[Waldo_fnc_CortexFlankStep, createHashMapFromArray [["group", _group],["drillToken",_token]], 0] call Waldo_fnc_CortexQueueJob;
if (missionNamespace getVariable ["Waldo_AIPass_Debug", false]) then {
    diag_log format ["[WMP CORTEX] %1 ADVANCE element=%2 points=%3", _group, count _element, count _points];
};
true

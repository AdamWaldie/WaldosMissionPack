/*
 * Author: WaldoTheWarfighter
 * Decides whether a squad in contact should flank, and if so plans the manoeuvre.
 *
 * Base of fire and manoeuvre uses multiple movement bounds. The leader, machine gunners and anti-tank gunners stay as the base of fire,
 * which Waldo_fnc_AIPassFireControl uses to suppress. Up to half the squad (2-5 riflemen) becomes
 * the manoeuvre element. The route has two legs: a wide swing about 70 degrees off the enemy's line
 * to the squad, then a close-in position about 60 degrees off, 35-60 m from the enemy. Each leg is cut
 * into bounds by Waldo_fnc_AIPassPlanRoute. Where a leg crosses a road
 * (Waldo_AIPass_StreetCrossing_Enable), the route stops at the near edge, throws smoke and crosses in
 * one bound to the far edge. Legs over water switch to the other flank or cancel the drill. When the
 * element reaches its flanking position it may go on to a final assault (Waldo_fnc_AIPassFlankStep).
 * Gates: infantry squad of at least Waldo_AIPass_Flank_MinGroupSize with 60% of its peak strength,
 * morale STEADY, a seen enemy between Waldo_AIPass_Flank_MinRange and MaxRange, no drill running, no
 * cooldown, and a roll against the group's behaviour profile flankChance (Waldo_fnc_AIPassProfile; a
 * failed roll waits 30 s).
 * Locality and authority: call where the group is local. The drill runs as its own scheduler job.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: enemies <ARRAY> - from Waldo_fnc_AIPassKnowledge
 *
 * Return Value:
 * Boolean - true when a drill started
 *
 * Example:
 * [_group, _state, _enemies] call Waldo_fnc_AIPassFlankStart;
 * Result: half the squad moves round the enemy's flank in covered bounds while the rest suppresses.
 *
 * Current caller: Waldo_fnc_AIPassGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
if (count (_state getOrDefault ["drill", createHashMap]) > 0) exitWith {false};
if ([_state, "flank"] call Waldo_fnc_AIPassCooldown) exitWith {false};
if ((_state getOrDefault ["moraleState", "STEADY"]) != "STEADY") exitWith {false};
private _leader = leader _group;
if (vehicle _leader != _leader) exitWith {false};
private _onFoot = (units _group) select {alive _x && {local _x} && {vehicle _x == _x}};
if (count _onFoot < (missionNamespace getVariable ["Waldo_AIPass_Flank_MinGroupSize", 6])) exitWith {false};
if (count _onFoot / ((_group getVariable ["Waldo_AIPass_PeakSize", count _onFoot]) max 1) < 0.6) exitWith {false};
private _targetIndex = _enemies findIf {
    (_x select 2) <= 15
    && {(_x select 3) >= (missionNamespace getVariable ["Waldo_AIPass_Flank_MinRange", 60])}
    && {(_x select 3) <= (missionNamespace getVariable ["Waldo_AIPass_Flank_MaxRange", 400])}
};
if (_targetIndex < 0) exitWith {false};
if (random 1 > ([_group, "flankChance"] call Waldo_fnc_AIPassProfile)) exitWith {
    [_state, "flank", 30] call Waldo_fnc_AIPassCooldown;
    false
};

private _enemyPos = (_enemies select _targetIndex) select 1;
private _distance = (_enemies select _targetIndex) select 3;
private _riflemen = _onFoot select {_x != _leader && {!(([_x] call Waldo_fnc_AIPassUnitRole) in ["MG", "AT", "LEADER"])}};
private _candidates = [];
{_candidates pushBack [_x distance2D _leader, _forEachIndex]} forEach _riflemen;
_candidates sort true;
private _size = ((floor (count _onFoot / 2)) min 5) min count _candidates;
if (_size < 2) exitWith {[_state, "flank", 30] call Waldo_fnc_AIPassCooldown; false};
private _element = (_candidates select [0, _size]) apply {_riflemen select (_x select 1)};

private _toGroup = _enemyPos getDir _leader;
private _legs = [];
{
    private _side = _x;
    private _wide = _enemyPos getPos [(_distance * 0.8) max 60, _toGroup + _side * 70];
    private _close = _enemyPos getPos [((_distance * 0.35) max 35) min 60, _toGroup + _side * 60];
    if (!surfaceIsWater _wide && {!surfaceIsWater _close}) exitWith {_legs = [_wide, _close]};
} forEach (selectRandom [[1, -1], [-1, 1]]);
if (_legs isEqualTo []) exitWith {[_state, "flank", 30] call Waldo_fnc_AIPassCooldown; false};

private _start = [0, 0, 0];
{_start = _start vectorAdd getPosATL _x} forEach _element;
_start = _start vectorMultiply (1 / count _element);
private _points = [_start, _legs, "FINAL", _group] call Waldo_fnc_AIPassPlanRoute;

_state set ["drill", createHashMapFromArray [
    ["type", "FLANK"], ["units", _element], ["points", _points], ["index", 0], ["stage", "START"], ["enemyPos", _enemyPos],
    ["disabled", []], ["spots", []], ["started", time], ["boundStart", time], ["pauseUntil", 0]
]];
[Waldo_fnc_AIPassFlankStep, createHashMapFromArray [["group", _group]], 0] call Waldo_fnc_AIPassQueueJob;
if (missionNamespace getVariable ["Waldo_AIPass_Debug", false]) then {
    diag_log format ["[WMP AI PASS] %1 FLANK element=%2 points=%3 crossings=%4", _group, count _element, count _points, {(_x select 1) == "CROSS_NEAR"} count _points];
};
true

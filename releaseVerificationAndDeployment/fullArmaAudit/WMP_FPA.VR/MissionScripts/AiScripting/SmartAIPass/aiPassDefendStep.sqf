/*
 * Author: WaldoTheWarfighter
 * Commits a defence line's reserve once, to where it is needed.
 *
 * Called from Waldo_fnc_AIPassGroupTick while a defending group is in CONTACT. The reserve moves to
 * the line spot of a fallen soldier when a third of the line is lost, or to the line spot nearest an
 * enemy believed within 60 m of the line. It then holds there, watching the same sector.
 * Locality and authority: call where the group is local.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: enemies <ARRAY> - from Waldo_fnc_AIPassKnowledge
 *
 * Return Value:
 * Boolean - true when the reserve was committed
 *
 * Example:
 * [_group, _state, _enemies] call Waldo_fnc_AIPassDefendStep;
 * Result: the reserve fills the gap where the line was broken.
 *
 * Current caller: Waldo_fnc_AIPassGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
if (_state getOrDefault ["reserveCommitted", false]) exitWith {false};
private _lineUnits = (units _group) select {((_x getVariable ["Waldo_AIPass_DefendPos", []]) param [2, ""]) == "LINE"};
private _reserve = (units _group) select {alive _x && {local _x} && {((_x getVariable ["Waldo_AIPass_DefendPos", []]) param [2, ""]) == "RESERVE"}};
if (_reserve isEqualTo [] || {_lineUnits isEqualTo []}) exitWith {false};
private _aliveLine = _lineUnits select {alive _x};
private _target = [];
if (count _aliveLine / count _lineUnits <= 0.67) then {
    private _fallen = _lineUnits select {!alive _x};
    if (_fallen isNotEqualTo []) then {_target = (_fallen select 0) getVariable ["Waldo_AIPass_DefendPos", []]};
};
if (_target isEqualTo []) then {
    {
        private _assignment = _x getVariable ["Waldo_AIPass_DefendPos", []];
        private _spot = _assignment param [0, []];
        if (count _spot >= 2 && {_enemies findIf {((_x select 1) distance2D _spot) < 60} >= 0}) exitWith {_target = _assignment};
    } forEach _lineUnits;
};
if (_target isEqualTo []) exitWith {false};
_target params ["_spot", "_sector"];
{
    private _position = _spot getPos [3 + _forEachIndex * 3, _sector + 90];
    _x setVariable ["Waldo_AIPass_DefendPos", [_position, _sector, "LINE"], true];
    _x setVariable ["Waldo_AIPass_DefendHolding", false];
    _x doMove _position;
} forEach _reserve;
_state set ["reserveCommitted", true];
_group setVariable ["Waldo_AIPass_DefendApplied", false];
[_group] call Waldo_fnc_AIPassDefendApplyLocal;
diag_log format ["[WMP AI PASS] %1 committed reserve (%2 soldiers)", _group, count _reserve];
true

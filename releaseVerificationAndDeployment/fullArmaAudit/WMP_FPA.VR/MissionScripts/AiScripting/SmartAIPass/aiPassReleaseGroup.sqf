/*
 * Author: WaldoTheWarfighter
 * Hands a group back to its own orders and removes everything the pass applied to it.
 *
 * Ends any flank drill (re-enabling only the AI features the drill itself disabled), rejoins the
 * search team, removes pass waypoints, restores behaviour and speed, remounts dismounted infantry,
 * and restores LAMBS group AI if the pass turned it off in "WMP" mode. Explicit orders (garrison,
 * clear building) are left in place; use their own release functions.
 * Locality and authority: call where the group is local; state and flags are machine-local.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: forget <BOOL> - also clear the managed flag so discovery may pick the group up again
 *    (optional, default: true)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_group] call Waldo_fnc_AIPassReleaseGroup;
 * Result: the group behaves exactly as it would without the pass.
 *
 * Current callers: Waldo_fnc_AIPassGroupTick (group became ineligible) and Waldo_fnc_AIPassStop.
 */

params [["_group", grpNull, [grpNull]], ["_forget", true, [false]]];
if (isNull _group) exitWith {};
private _state = _group getVariable ["Waldo_AIPass_State", createHashMap];
if (local _group && {count _state > 0}) then {
    if (count (_state getOrDefault ["drill", createHashMap]) > 0) then {[_group, _state, "RELEASE"] call Waldo_fnc_AIPassFlankEnd};
    [_group, _state] call Waldo_fnc_AIPassRestoreCalm;
};
if (_group getVariable ["Waldo_AIPass_LambsDisabledByPass", false]) then {
    _group setVariable ["lambs_danger_disableGroupAI", false, true];
    _group setVariable ["Waldo_AIPass_LambsDisabledByPass", nil];
};
_group setVariable ["Waldo_AIPass_State", nil];
if (_forget) then {_group setVariable ["Waldo_AIPass_Managed", nil]};

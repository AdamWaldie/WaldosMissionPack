/*
 * Author: WaldoTheWarfighter
 * Hands a group back to its own orders and removes everything the pass applied to it.
 *
 * Ends any flank drill (re-enabling only the AI features the drill itself disabled), rejoins the
 * search team, removes pass waypoints, restores behaviour and speed without ordering passengers to board,
 * and restores LAMBS group AI if the pass turned it off in "WMP" mode. Explicit orders (garrison,
 * clear building) are left in place; use their own release functions.
 * Locality and authority: call where the group is local; state and flags are machine-local.
 *
 * Review contract: Only the current group owner restores the public LAMBS flag. Changed restoration checkpoints are public and consumed on ownership adoption.
 *
 * A Zeus takeover yields movement, formation, behaviour and speed to the curator while still restoring
 * Cortex-owned AI feature switches and removing Cortex waypoints. Repeat/JIP: only tracked changes are
 * restored; repeated cleanup is harmless and never boards passengers.
 * Public remount intent is cancelled even when owner migration left no local behaviour map.
 * Arguments:
 * 0: group <GROUP>
 * 1: forget <BOOL> - also clear the managed flag so discovery may pick the group up again
 *    (optional, default: true)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_group] call Waldo_fnc_CortexReleaseGroup;
 * Result: the group behaves exactly as it would without the pass.
 *
 * Current callers: Waldo_fnc_CortexGroupTick (group became ineligible) and Waldo_fnc_CortexStop.
 */

params [["_group", grpNull, [grpNull]], ["_forget", true, [false]]];
if (isNull _group) exitWith {};
private _state = _group getVariable ["Waldo_AIPass_State", createHashMap];
private _yieldToExternal=local _group && {[_group] call Waldo_fnc_CortexZeusHeld};
if (local _group && {count _state > 0 || {(_group getVariable ["Waldo_Cortex_Remount",[]]) isNotEqualTo []}}) then {
    if (count (_state getOrDefault ["drill", createHashMap]) > 0) then {[_group, _state, ["RELEASE","ZEUS"] select _yieldToExternal] call Waldo_fnc_CortexFlankEnd};
    [_group, _state, false, _yieldToExternal] call Waldo_fnc_CortexRestoreCalm;
};
if (local _group && {_group getVariable ["Waldo_AIPass_LambsDisabledByPass", false]}) then {
    _group setVariable ["lambs_danger_disableGroupAI", false, true];
    _group setVariable ["Waldo_AIPass_LambsDisabledByPass", nil, true];
};
_group setVariable ["Waldo_AIPass_State", nil];
if (_forget) then {_group setVariable ["Waldo_AIPass_Managed", nil]};

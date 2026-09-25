/*
 * Author: WaldoTheWarfighter
 * Ends a drill (flank or bounding advance).
 *
 * Re-enables only the AI features the drill disabled. A drill that completed, or stopped because the
 * enemy is close, leaves its members holding the ground they took: they are recorded as "holders" and
 * rejoin formation later (Waldo_fnc_AIPassGroupTick, Waldo_fnc_AIPassRestoreCalm,
 * Waldo_fnc_AIPassRetreat). Any other ending (losses, the squad leaving contact, Zeus taking the
 * group, or release) orders members to follow the leader again at once. The drill's cooldown starts.
 * Locality and authority: call where the group is local.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: reason <STRING> - COMPLETE, CLOSE, ABORT, LOSSES or RELEASE
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_group, _state, "COMPLETE"] call Waldo_fnc_AIPassFlankEnd;
 * Result: the element stays on the enemy's flank instead of running back to the leader.
 *
 * Current callers: Waldo_fnc_AIPassFlankStep and Waldo_fnc_AIPassReleaseGroup.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_reason", "", [""]]];
private _drill = _state getOrDefault ["drill", createHashMap];
if (count _drill == 0) exitWith {};
{
    _x params ["_unit", "_feature"];
    if (alive _unit && {local _unit}) then {_unit enableAI _feature};
} forEach (_drill getOrDefault ["disabled", []]);
private _members = (_drill getOrDefault ["units", []]) select {alive _x && {local _x} && {group _x == _group}};
if (_reason in ["COMPLETE", "CLOSE"]) then {
    private _holders = _state getOrDefault ["holders", []];
    {_holders pushBackUnique _x} forEach _members;
    _state set ["holders", _holders];
} else {
    private _leader = leader _group;
    {_x doFollow _leader} forEach _members;
};
private _type = _drill getOrDefault ["type", "FLANK"];
_state deleteAt "drill";
[_state, toLowerANSI _type, missionNamespace getVariable ["Waldo_AIPass_Flank_Cooldown", 90]] call Waldo_fnc_AIPassCooldown;
if (_reason == "COMPLETE") then {
    private _counter = ["Waldo_AIPass_FlanksCompleted", "Waldo_AIPass_AdvancesCompleted"] select (_type == "ADVANCE");
    missionNamespace setVariable [_counter, (missionNamespace getVariable [_counter, 0]) + 1];
};
if (missionNamespace getVariable ["Waldo_AIPass_Debug", false]) then {diag_log format ["[WMP AI PASS] %1 %2 end reason=%3", _group, _type, _reason]};

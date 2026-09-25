/*
 * Author: WaldoTheWarfighter
 * Ends a flank drill and hands the element back to the squad.
 *
 * Re-enables only the AI features the drill disabled, orders every element member to follow the
 * leader again, clears the drill and starts Waldo_AIPass_Flank_Cooldown.
 * Locality and authority: call where the group is local.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: reason <STRING> - COMPLETE, ABORT, LOSSES, CLOSE or RELEASE (for diagnostics)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_group, _state, "COMPLETE"] call Waldo_fnc_AIPassFlankEnd;
 * Result: the element rejoins formation on its new, flanking ground.
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
private _leader = leader _group;
{
    if (alive _x && {local _x} && {group _x == _group}) then {_x doFollow _leader};
} forEach (_drill getOrDefault ["units", []]);
_state deleteAt "drill";
[_state, "flank", missionNamespace getVariable ["Waldo_AIPass_Flank_Cooldown", 90]] call Waldo_fnc_AIPassCooldown;
if (_reason == "COMPLETE") then {
    missionNamespace setVariable ["Waldo_AIPass_FlanksCompleted", (missionNamespace getVariable ["Waldo_AIPass_FlanksCompleted", 0]) + 1];
};
if (missionNamespace getVariable ["Waldo_AIPass_Debug", false]) then {diag_log format ["[WMP AI PASS] %1 FLANK end reason=%2", _group, _reason]};

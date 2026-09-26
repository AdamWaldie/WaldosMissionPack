/*
 * Author: WaldoTheWarfighter
 * Publishes what the Smart AI Pass has temporarily changed on a group, so any machine can undo it.
 *
 * Group state and drill records are machine-local. When a group changes owner (a headless-client
 * handover, a return to the server, or a headless client disconnecting), the new owner cannot see
 * them. This records the few changes that outlive the owner - squad behaviour and speed, AI features
 * a drill turned off, and stances the pass set - as one broadcast group variable,
 * Waldo_AIPass_Restore, which Waldo_fnc_AIPassAdoptRestore reads on the new owner. The variable is
 * only sent when its content changes, never on every step, and is cleared once the squad is back to
 * normal.
 * Locality and authority: runs where the group is local; other calls do nothing.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP> - the group's pass state (Waldo_fnc_AIPassGroupState); an empty map publishes nothing to restore
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_group, [_group] call Waldo_fnc_AIPassGroupState] call Waldo_fnc_AIPassPublishRestore;
 * Result: the group's current restore record is published if it changed.
 *
 * Current callers: Waldo_fnc_AIPassGroupTick, Waldo_fnc_AIPassFlankStep, Waldo_fnc_AIPassFlankEnd,
 * Waldo_fnc_AIPassRestoreCalm and Waldo_fnc_AIPassReleaseGroup.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]]];
if (isNull _group || {!local _group}) exitWith {};
private _record = [];
if (_state getOrDefault ["behaviourChanged", false]) then {
    _record pushBack ["behaviour", [_state getOrDefault ["baseBehaviour", "AWARE"], _state getOrDefault ["hadContact", false]]];
};
if (_state getOrDefault ["speedChanged", false]) then {
    _record pushBack ["speed", _state getOrDefault ["baseSpeed", "NORMAL"]];
};
private _features = ((_state getOrDefault ["drill", createHashMap]) getOrDefault ["disabled", []]) select {alive (_x select 0)};
if (_features isNotEqualTo []) then {_record pushBack ["features", _features]};
private _stances = (units _group) select {alive _x && {_x getVariable ["Waldo_AIPass_StanceSet", false]}};
if (_stances isNotEqualTo []) then {_record pushBack ["stance", _stances]};
if (_record isEqualTo (_group getVariable ["Waldo_AIPass_RestorePublished", []])) exitWith {};
_group setVariable ["Waldo_AIPass_RestorePublished", _record];
if (_record isEqualTo []) then {
    _group setVariable ["Waldo_AIPass_Restore", nil, true];
} else {
    _group setVariable ["Waldo_AIPass_Restore", _record, true];
};

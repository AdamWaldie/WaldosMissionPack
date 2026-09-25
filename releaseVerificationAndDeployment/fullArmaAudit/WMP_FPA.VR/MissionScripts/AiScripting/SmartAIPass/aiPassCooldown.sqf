/*
 * Author: WaldoTheWarfighter
 * Reads or sets a named cooldown in a group's pass state.
 *
 * Locality and authority: machine-local.
 *
 * Arguments:
 * 0: state <HASHMAP> - from Waldo_fnc_AIPassGroupState
 * 1: name <STRING>
 * 2: seconds <NUMBER> - start a cooldown of this length; omit or -1 to only read (optional, default: -1)
 *
 * Return Value:
 * Boolean - true while the cooldown is still running (before any new one is set)
 *
 * Example:
 * if ([_state, "flank"] call Waldo_fnc_AIPassCooldown) exitWith {};
 * Result: the flank drill is not attempted again until its cooldown ends.
 *
 * Current callers: behaviour functions of the Smart AI Pass.
 */

params [["_state", createHashMap, [createHashMap]], ["_name", "", [""]], ["_seconds", -1, [0]]];
private _cooldowns = _state getOrDefault ["cooldowns", createHashMap];
private _running = time < (_cooldowns getOrDefault [_name, -1]);
if (_seconds >= 0) then {
    _cooldowns set [_name, time + _seconds];
    _state set ["cooldowns", _cooldowns];
};
_running

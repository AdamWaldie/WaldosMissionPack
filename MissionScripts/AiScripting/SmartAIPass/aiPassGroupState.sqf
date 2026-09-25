/*
 * Author: WaldoTheWarfighter
 * Returns a group's Smart AI Pass state map, creating it on first use.
 *
 * The map lives on the group as a machine-local variable, so it is never broadcast. A new owner
 * after a locality change starts a fresh map and re-reads the situation from engine knowledge.
 * Keys: phase (CALM, CONTACT, SECURITY, SEARCH, REGROUP, RETREAT), morale (0-1), moraleState
 * (STEADY, SHAKEN, BROKEN), cooldowns (map of name to time), plus per-phase fields set by
 * Waldo_fnc_AIPassGroupTick and the behaviour functions.
 * Locality and authority: machine-local.
 *
 * Arguments:
 * 0: group <GROUP>
 *
 * Return Value:
 * HashMap - the state map (the same object on every call)
 *
 * Example:
 * private _state = [_group] call Waldo_fnc_AIPassGroupState;
 * Result: the group's live pass state.
 *
 * Current callers: Waldo_fnc_AIPassGroupTick, Waldo_fnc_AIPassReinforce and order functions.
 */

params [["_group", grpNull, [grpNull]]];
private _state = _group getVariable ["Waldo_AIPass_State", createHashMap];
if (count _state == 0) then {
    _state = createHashMapFromArray [
        ["phase", "CALM"], ["morale", 1], ["moraleState", "STEADY"], ["cooldowns", createHashMap]
    ];
    _group setVariable ["Waldo_AIPass_State", _state];
};
_state

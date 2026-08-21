/*
 * Author: WaldoTheWarfighter
 * Removes Advanced Conversation assignments from one object, group, or object array.
 * Locality/authority: server-only. Repeat/JIP behaviour: repeat-safe full snapshot reconciliation.
 * Arguments: targets. Return Value: BOOL. Current callers: scripts and ZEN.
 * Example: [this] call Waldo_fnc_ConversationClear;
 */
params ["_targetsInput"];
if (!isServer) exitWith {false};
private _registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", createHashMap];
private _changed = false;
{
    private _key = netId _x; if (_key == "0:0") then {_key = str _x};
    private _entry = _registry getOrDefault [_key, createHashMap];
    if (count _entry > 0 && {_entry getOrDefault ["kind", ""] == "ADVANCED"}) then {
        _registry deleteAt _key; _x setVariable ["Waldo_Dialogue_Available", false, true]; _x setVariable ["Waldo_Dialogue_Occupied", false, true]; _changed = true;
    };
} forEach ([_targetsInput] call Waldo_fnc_DialogueResolveTargets);
missionNamespace setVariable ["Waldo_Dialogue_Registry", _registry];
if (_changed) then {[] call Waldo_fnc_DialoguePublishState};
_changed

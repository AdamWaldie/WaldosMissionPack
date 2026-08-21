/*
 * Author: WaldoTheWarfighter
 * Assigns a registered Advanced Conversation to one NPC, group, or object array.
 * Locality/authority: server-only; definitions and hooks remain in the server registry.
 * Repeat/JIP behaviour: replaces the speaker entry and republishes a serialisable action snapshot.
 * Arguments: targets, conversation ID STRING, remove-after-use BOOL. Return Value: BOOL.
 * Current callers: Eden init fields, scripts and ZEN. Example: [this,"CHECKPOINT"] call Waldo_fnc_ConversationAssign;
 */
params ["_targetsInput", ["_conversationId", "", [""]], ["_removeAfterUse", false, [true]]];
if (!isServer) exitWith {false};
[] call Waldo_fnc_DialogueBootstrap;
_conversationId = toUpperANSI _conversationId;
private _definitions = missionNamespace getVariable ["Waldo_Conversation_Definitions", createHashMap];
if !(_conversationId in keys _definitions) exitWith {diag_log format ["[WMP CONVERSATION] Cannot assign unknown id '%1'.", _conversationId]; false};
private _targets = [_targetsInput] call Waldo_fnc_DialogueResolveTargets;
if (count _targets == 0) exitWith {false};
private _registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", createHashMap];
{
    private _key = netId _x; if (_key == "0:0") then {_key = str _x};
    _registry set [_key, createHashMapFromArray [["kind", "ADVANCED"], ["speaker", _x], ["conversationId", _conversationId], ["removeAfterUse", _removeAfterUse], ["activeSession", ""]]];
    _x setVariable ["Waldo_Dialogue_Available", true, true];
    _x setVariable ["Waldo_Dialogue_Occupied", false, true];
} forEach _targets;
missionNamespace setVariable ["Waldo_Dialogue_Registry", _registry];
[] call Waldo_fnc_DialoguePublishState;
true

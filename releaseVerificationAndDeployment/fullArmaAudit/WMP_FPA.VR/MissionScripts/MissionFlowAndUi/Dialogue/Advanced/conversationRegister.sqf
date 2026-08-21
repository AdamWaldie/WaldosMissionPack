/*
 * Author: WaldoTheWarfighter
 * Registers a validated named Advanced Conversation while retaining all conditions and hooks server-side.
 * Locality/authority: server-only. Repeat/JIP behaviour: repeat-safe replacement for future sessions.
 * Arguments: 0 definition HASHMAP. Return Value: BOOL. Current callers: ConversationCreate and power-user scripts.
 * Example: [_definition] call Waldo_fnc_ConversationRegister;
 */
params [["_definition", createHashMap, [createHashMap]]];
if (!isServer) exitWith {false};
[] call Waldo_fnc_DialogueBootstrap;
private _result = [_definition] call Waldo_fnc_ConversationValidateDefinition;
if !(_result select 0) exitWith {diag_log format ["[WMP CONVERSATION] Definition rejected: %1", (_result select 1) joinString "; "]; false};
private _definitions = missionNamespace getVariable ["Waldo_Conversation_Definitions", createHashMap];
private _id = toUpperANSI (_definition get "id");
_definition set ["id", _id];
_definition set ["startNode", toUpperANSI (_definition get "startNode")];
_definitions set [_id, _definition];
missionNamespace setVariable ["Waldo_Conversation_Definitions", _definitions];
missionNamespace setVariable ["Waldo_Conversation_PublicIds", keys _definitions, true];
diag_log format ["[WMP CONVERSATION] Registered id=%1 nodes=%2.", _id, count keys (_definition get "nodes")];
true

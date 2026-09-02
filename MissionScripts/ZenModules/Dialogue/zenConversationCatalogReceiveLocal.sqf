/*
 * Author: WaldoTheWarfighter
 * Accepts one revisioned Advanced Conversation ID catalogue from the server for the pending local
 * ZEN request. Full definitions never enter curator clients.
 * Locality/authority: interface-local and accepts server remote execution only.
 * Repeat/JIP behaviour: request tokens discard late responses from an older module invocation.
 * Arguments: request token STRING, revision NUMBER, IDs ARRAY. Return Value: BOOL.
 * Current callers: ZenConversationCatalogServer responses.
 * Example: server remote execution only.
 */
params [["_requestToken", "", [""]], ["_revision", -1, [0]], ["_ids", [], [[]]]];
if (!hasInterface || {remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}}) exitWith {false};
if (_requestToken != missionNamespace getVariable ["Waldo_Conversation_PendingCatalogToken", ""]) exitWith {false};
missionNamespace setVariable ["Waldo_Conversation_CatalogResponse", [_requestToken, _revision, +_ids]];
true

/*
 * Author: WaldoTheWarfighter
 * Receives the authenticated result of a Conversation Author registration/assignment request and
 * presents it through the WMP notification flow.
 * Locality/authority: interface-local and accepts server remote execution only.
 * Repeat/JIP behaviour: request IDs let the open editor ignore stale acknowledgements.
 * Arguments: request ID STRING, success BOOL, message STRING, warnings ARRAY. Return Value: BOOL.
 * Current caller: ZenConversationAuthorServer.
 * Example: server remote execution only.
 */
params [["_requestId", "", [""]], ["_success", false, [true]], ["_message", "", [""]], ["_warnings", [], [[]]]];
if (!hasInterface || {remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}}) exitWith {false};
if (_requestId != missionNamespace getVariable ["Waldo_Conversation_AuthorLastRequest", ""]) exitWith {false};
missionNamespace setVariable ["Waldo_Conversation_AuthorLastResult", [_requestId, _success, _message, +_warnings]];
private _details = if (count _warnings > 0) then {format ["%1 Warning: %2", _message, _warnings joinString "; "]} else {_message};
["CONVERSATION", _details, if (_success) then {"SUCCESS"} else {"WARNING"}, "CONVERSATION_AUTHOR", 8]
    call Waldo_fnc_FeatureNotifyLocal;
_success

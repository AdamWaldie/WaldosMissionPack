/*
 * Author: WaldoTheWarfighter
 * Returns the current server-authoritative Advanced Conversation ID catalogue to one authenticated
 * curator without exposing definitions, conditions or callbacks.
 * Locality/authority: server-only remote endpoint; the requester must own the supplied player and
 * have an assigned curator logic. Repeat/JIP behaviour: every request returns a complete revisioned
 * snapshot, so JIP and late registrations do not depend on public-variable arrival order.
 * Arguments: requester OBJECT, request token STRING. Return Value: BOOL.
 * Current caller: ZEN Conversation Assign and Author clients.
 * Example: [player,"CATALOG_1"] remoteExecCall ["Waldo_fnc_ZenConversationCatalogServer",2];
 */
params [["_requester", objNull, [objNull]], ["_requestToken", "", [""]]];
if (!isServer || {isNull _requester} || {_requestToken == ""}) exitWith {false};
if (remoteExecutedOwner <= 0 || {owner _requester != remoteExecutedOwner} || {isNull getAssignedCuratorLogic _requester}) exitWith {false};
[] call Waldo_fnc_DialogueBootstrap;
private _definitions = missionNamespace getVariable ["Waldo_Conversation_Definitions", createHashMap];
private _ids = keys _definitions;
_ids sort true;
[_requestToken, missionNamespace getVariable ["Waldo_Conversation_CatalogRevision", 0], _ids]
    remoteExecCall ["Waldo_fnc_ZenConversationCatalogReceiveLocal", owner _requester];
true

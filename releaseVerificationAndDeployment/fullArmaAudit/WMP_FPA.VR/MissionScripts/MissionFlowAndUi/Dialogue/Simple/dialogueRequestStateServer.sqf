/*
 * Author: WaldoTheWarfighter
 * Authenticates a player JIP snapshot request and returns the current dialogue descriptors.
 * Locality/authority: remote server endpoint. Repeat/JIP behaviour: safe to request repeatedly.
 * Arguments: 0 requester <OBJECT>. Return Value: BOOL.
 * Current caller: DialogueBootstrap on each interface client. Example: [player] remoteExecCall ["Waldo_fnc_DialogueRequestStateServer",2];
 */
params [["_requester", objNull, [objNull]]];
if (!isServer || {isNull _requester}) exitWith {false};
if (isRemoteExecuted && {owner _requester != remoteExecutedOwner}) exitWith {false};
[owner _requester] call Waldo_fnc_DialoguePublishState;
true

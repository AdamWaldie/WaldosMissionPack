/*
 * Author: WaldoTheWarfighter
 * Starts an assigned conversation from trusted server script code without a player action.
 * Locality/authority: server-only and delegates to the same lock/validation path.
 * Repeat/JIP behaviour: respects the per-NPC active lock. Arguments: speaker OBJECT, caller OBJECT.
 * Return Value: BOOL. Current caller: mission scripts. Example: [guide,player] call Waldo_fnc_ConversationStart;
 */
params [["_speaker", objNull, [objNull]], ["_caller", objNull, [objNull]]];
if (!isServer) exitWith {false};
[_speaker, _caller] call Waldo_fnc_DialogueRequestStartServer

/*
 * Author: WaldoTheWarfighter
 * Gives Zeus an explicit start/cancel control for an assigned Advanced Conversation.
 * Locality/authority: curator client through an authenticated server bridge.
 * Repeat/JIP behaviour: respects the active speaker lock and current session token.
 * Arguments: module position ARRAY, selected object OBJECT. Return Value: Nothing.
 * Current caller: ZEN "Conversation - Start or Cancel". Example: place directly on an NPC.
 */
params ["_modulePos", ["_target", objNull, [objNull]]];
if (isNull _target) exitWith {["CONVERSATION", "Place this module directly on an NPC.", "WARNING", "CONVERSATION_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal};
[
    "Control Conversation",
    [["COMBO", ["Operation", "Start with yourself as the participant, or cancel the current session."], [["START", "CANCEL"], ["Start", "Cancel"], 0], false]],
    {params ["_args", "_saved"]; _args params ["_operation"]; _saved params ["_target"]; ["ADVANCED_CONTROL", _target, [_operation], player] remoteExecCall ["Waldo_fnc_ZenDialogueServer", 2]},
    {}, [_target]
] call zen_dialog_fnc_create;

/*
 * Author: WaldoTheWarfighter
 * Lets a curator assign an already script-authored Advanced Conversation by friendly ID.
 * Locality/authority: curator client; server retains definition conditions and callbacks.
 * Repeat/JIP behaviour: assignment replaces the selected speaker/group snapshot entry.
 * Arguments: module position ARRAY, selected object OBJECT. Return Value: Nothing.
 * Current caller: ZEN "Conversation: Assign". Example: place directly on an NPC.
 */
params ["_modulePos", ["_target", objNull, [objNull]]];
if (isNull _target) exitWith {["CONVERSATION", "Place this module directly on an NPC.", "WARNING", "CONVERSATION_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal};
private _ids = missionNamespace getVariable ["Waldo_Conversation_PublicIds", []]; _ids sort true;
if (count _ids == 0) exitWith {["CONVERSATION", "No named conversations have been registered by mission scripts.", "WARNING", "CONVERSATION_ZEN", 7] call Waldo_fnc_FeatureNotifyLocal};
[
    "Assign Named Conversation",
    [
        ["COMBO", ["Conversation", "Select a server-registered conversation."], [_ids, _ids, 0], false],
        ["CHECKBOX", ["Apply to entire group", "Assign this conversation to every NPC in the group."], false, false],
        ["CHECKBOX", ["Remove after completion", "Make the assigned conversation one-shot."], false, false]
    ],
    {params ["_args", "_saved"]; _args params ["_id", "_group", "_once"]; _saved params ["_target"]; ["ADVANCED_ASSIGN", _target, [_id, _group, _once], player] remoteExecCall ["Waldo_fnc_ZenDialogueServer", 2]},
    {}, [_target]
] call zen_dialog_fnc_create;

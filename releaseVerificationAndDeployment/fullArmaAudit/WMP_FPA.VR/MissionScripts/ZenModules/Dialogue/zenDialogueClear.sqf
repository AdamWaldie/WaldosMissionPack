/*
 * Author: WaldoTheWarfighter
 * Requests removal of either dialogue component from a selected NPC or its group.
 * Locality/authority: curator client to authenticated server bridge.
 * Repeat/JIP behaviour: repeat-safe and reconciled for every client.
 * Arguments: module position ARRAY, selected object OBJECT. Return Value: Nothing.
 * Current caller: ZEN "Dialogue - Clear". Example: place directly on an NPC.
 */
params ["_modulePos", ["_target", objNull, [objNull]]];
if (isNull _target) exitWith {["DIALOGUE", "Place this module directly on an NPC.", "WARNING", "DIALOGUE_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal};
[
    "Clear Dialogue",
    [["CHECKBOX", ["Clear entire group", "Remove dialogue from every NPC in this unit's group."], false, false]],
    {params ["_args", "_saved"]; _args params ["_group"]; _saved params ["_target"]; ["CLEAR", _target, [_group], player] remoteExecCall ["Waldo_fnc_ZenDialogueServer", 2]},
    {}, [_target]
] call zen_dialog_fnc_create;

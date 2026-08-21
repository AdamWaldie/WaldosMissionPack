/*
 * Author: WaldoTheWarfighter
 * Opens the beginner ZEN workflow for applying a named Simple Dialogue archetype to an NPC or group.
 * Locality/authority: curator-client dialog; mutation is authenticated on the server.
 * Repeat/JIP behaviour: replaces existing assignments through the public SimpleDialogue API.
 * Arguments: module position ARRAY, selected object OBJECT. Return Value: Nothing.
 * Current caller: ZEN "Dialogue - Apply Simple Archetype". Example: place the module on an NPC.
 */
params ["_modulePos", ["_target", objNull, [objNull]]];
if (isNull _target || {!(_target isKindOf "CAManBase")}) exitWith {["DIALOGUE", "Place this module directly on an NPC.", "WARNING", "DIALOGUE_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal};
private _ids = missionNamespace getVariable ["Waldo_Dialogue_PublicArchetypeIds", ["CIVILIAN", "CIVILIAN_FRIENDLY", "CIVILIAN_WARY"]];
_ids sort true;
[
    "Apply Simple Dialogue Archetype",
    [
        ["COMBO", ["Archetype", "A random line is chosen each time the NPC is used."], [_ids, _ids, 0], false],
        ["CHECKBOX", ["Apply to entire group", "Give every NPC in the selected unit's group the same archetype."], false, false],
        ["CHECKBOX", ["Remove after first completed use", "Make this a one-shot interaction."], false, false]
    ],
    {params ["_args", "_saved"]; _args params ["_id", "_group", "_once"]; _saved params ["_target"]; ["SIMPLE_ARCHETYPE", _target, [_id, _group, _once], player] remoteExecCall ["Waldo_fnc_ZenDialogueServer", 2]},
    {}, [_target]
] call zen_dialog_fnc_create;

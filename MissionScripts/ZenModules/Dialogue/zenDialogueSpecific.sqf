/*
 * Author: WaldoTheWarfighter
 * Opens the beginner ZEN workflow for assigning up to 32 ordered Simple Dialogue lines.
 * Locality/authority: curator-client dialog; server validates target and text.
 * Repeat/JIP behaviour: replaces existing assignments and republishes the action snapshot.
 * Arguments: module position ARRAY, selected object OBJECT. Return Value: Nothing.
 * Current caller: ZEN "Dialogue - Assign Simple Lines". Example: enter lines separated by |.
 */
params ["_modulePos", ["_target", objNull, [objNull]]];
if (isNull _target || {!(_target isKindOf "CAManBase")}) exitWith {["DIALOGUE", "Place this module directly on an NPC.", "WARNING", "DIALOGUE_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal};
[
    "Assign Simple Dialogue Lines",
    [
        ["EDIT", ["Dialogue", "Write lines in speaking order and separate each line with the | character."], "Hello there.|The clinic is at the end of the road."],
        ["CHECKBOX", ["Apply to entire group", "Give every NPC in the selected unit's group these lines."], false, false],
        ["CHECKBOX", ["Remove after first completed use", "Make this a one-shot interaction."], false, false]
    ],
    {params ["_args", "_saved"]; _args params ["_text", "_group", "_once"]; _saved params ["_target"]; ["SIMPLE_LINES", _target, [_text, _group, _once], player] remoteExecCall ["Waldo_fnc_ZenDialogueServer", 2]},
    {}, [_target]
] call zen_dialog_fnc_create;

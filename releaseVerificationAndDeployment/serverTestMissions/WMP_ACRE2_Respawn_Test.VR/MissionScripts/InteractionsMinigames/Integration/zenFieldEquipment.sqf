/*
 * Author: WaldoTheWarfighter
 * Opens the ZEN setup dialog which adds a WMP Field Equipment procedure to the selected object.
 * All choices are named operator concepts; challenge IDs, icons and explosive classnames remain
 * internal. The EOD mode uses the established bomb-defusal wrapper and the other modes use the
 * shared interaction framework with a curated success outcome.
 *
 * Locality and repeat/JIP behaviour:
 * Interface-only dialog. It requires the object actually selected under the module and sends named
 * data to the authenticated server runtime bridge. The server republishes repeat-safe setup to all
 * interface clients and JIP while retaining authoritative callbacks.
 *
 * Arguments: 0 module position <ARRAY>; 1 selected object <OBJECT>.
 * Return Value: Nothing.
 * Current caller: Add WMP Field Equipment Interaction ZEN module.
 * Example: [_modulePos, _objectPos] call Waldo_fnc_ZenFieldEquipment;
 */
params [["_modulePos", [], [[]]], ["_objectPos", objNull, [objNull]]];
if (!hasInterface) exitWith {};
if (isNull _objectPos || {_objectPos isKindOf "Logic"}) exitWith {
    ["FIELD EQUIPMENT", "Place this module directly on the object that should receive the interaction.", "ERROR", "ZEN_FIELD_EQUIPMENT"] call Waldo_fnc_FeatureNotifyLocal;
};
private _procedures = ["circuit"] call Waldo_fnc_MiniGameInteractionOptions;
private _modes = ["STANDARD", "EOD"];
private _outcomes = ["COMPLETE", "ACTIVATE", "DEACTIVATE", "UNLOCK", "DESTROY", "DELETE"];
[
    "Add WMP Field Equipment Interaction",
    [
        ["COMBO", ["Interaction type", "Standard uses any shared procedure. EOD Bomb Defusal disarms on success and can detonate on failure."], [_modes, ["Standard field equipment", "EOD bomb defusal"], 0]],
        ["COMBO", ["Procedure", "The equipment challenge the player completes."], _procedures],
        ["EDIT", ["Action label", "The interaction text players see on this object."], ["Operate Equipment"]],
        ["COMBO", ["Difficulty", "Changes procedure tolerances and time pressure."], [["easy", "standard", "hard", "expert"], ["Easy", "Standard", "Hard", "Expert"], 1]],
        ["COMBO", ["Success outcome", "Complete only records success. Other choices perform the named server-owned object change."], [_outcomes, ["Record completion only", "Enable simulation / show", "Disable simulation", "Unlock", "Destroy", "Delete"], 0]],
        ["CHECKBOX", ["Repeat after success", "Keep the action available and reset it for another successful use."], false],
        ["CHECKBOX", ["Retry after failure", "Allow another player to retry a failed standard procedure."], true],
        ["CHECKBOX", ["Direct ACE action", "Show directly under ACE Main Actions instead of the Field Equipment category."], false],
        ["CHECKBOX", ["EOD failure detonates", "EOD mode only: a failed, timed-out or aborted procedure detonates the device."], true]
    ],
    {
        params ["_values", "_target"];
        _values params ["_mode", "_procedure", "_title", "_difficulty", "_outcome", "_repeat", "_retry", "_direct", "_detonate"];
        ["FIELD_EQUIPMENT", [_target, _mode, _procedure, _title, _difficulty, _outcome, _repeat, _retry, _direct, _detonate]] call Waldo_fnc_FeatureRuntimeApply;
    },
    {},
    _objectPos
] call zen_dialog_fnc_create;

/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: plants a signal tracker only on the object or unit directly under the
 * module, visible to a chosen side (Waldo_fnc_Tracker). Empty-ground placement is rejected before
 * opening the dialog, so a nearby unrelated entity can never be selected accidentally.
 * Locality and authority: Curator interface gathers options; Waldo_fnc_Tracker performs the
 * authoritative attachment. Empty-target placement is rejected locally.
 * Repeat/JIP: Each placement is a separate request. Tracker state and map presentation follow
 * the tracker feature's server and client replay path.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module
 * 1: objectPos <OBJECT> - object or unit the module was dropped on
 *
 * Return Value:
 * Nothing - a valid dialog forwards the selected object to Waldo_fnc_Tracker.
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenTracker;
 *
 * Current caller: the ZEN "Tracker: Attach to Selected Object" module.
 * Result: A labelled side-visible tracker is requested for the exact selected object.
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", "_objectPos"];

if (isNull _objectPos) exitWith {
    ["TRACKER NOT PLANTED", "Place this module directly on the object or unit to track.", 8, "FAILURE"] call Waldo_fnc_JammingNotice;
};

[
    "Plant Signal Tracker",
    [
        ["COMBO", ["Tracked By", "Which side can see the tracker on their map."],
            [
                ["ALL", "WEST", "EAST", "IND", "CIV"],
                ["All Sides", "BLUFOR", "OPFOR", "INDFOR", "CIVILIAN"],
                0
            ],
        false],
        ["EDIT", ["Tracker Label", "Optional map label. Leave blank for the generated TRK-number."], ""],
        ["CHECKBOX", ["Start Active", "Show the tracker immediately after it is attached."], true, false]
    ],
    {
        params ["_args", "_pos"];
        _args params ["_sideStr", "_label", "_active"];
        _pos params ["_target"];
        if (isNull _target) exitWith {
            ["TRACKER NOT PLANTED", "The selected object or unit is no longer available.", 8, "FAILURE"] call Waldo_fnc_JammingNotice;
        };

        [_target, _sideStr, _label, _active, player] remoteExecCall ["Waldo_fnc_ZenTrackerServer", 2];
    },
    {},
    [_objectPos]
] call zen_dialog_fnc_create;

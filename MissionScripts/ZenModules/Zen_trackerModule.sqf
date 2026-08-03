/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: plants a signal tracker only on the object or unit directly under the
 * module, visible to a chosen side (Waldo_fnc_Tracker). Empty-ground placement is rejected before
 * opening the dialog, so a nearby unrelated entity can never be selected accidentally.
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

        [_target, _sideStr, _label, _active] call Waldo_fnc_Tracker;
        ["TRACKER PLANTED", format ["Tracking access: %1. Label: %2.", _sideStr, if (_label isEqualTo "") then {"AUTO"} else {_label}], 6, "SUCCESS"] call Waldo_fnc_JammingNotice;
    },
    {},
    [_objectPos]
] call zen_dialog_fnc_create;

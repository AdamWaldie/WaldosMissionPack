/*
 * Author: Waldo
 * Zeus module handler: plants a signal tracker on the nearest unit/vehicle to the module position,
 * visible to a chosen side (Waldo_fnc_Tracker). Lets a curator mark a target for a side to follow
 * on the map without touching the target.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module
 * 1: objectPos <OBJECT> - object the module was dropped on (unused)
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenTracker;
 *
 * Public: No
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", "_objectPos"];

[
    "Plant Signal Tracker",
    [
        ["COMBO", ["Tracked By", "Which side can see the tracker on their map."],
            [
                ["ALL", "WEST", "EAST", "IND", "CIV"],
                ["All Sides", "BLUFOR", "OPFOR", "INDFOR", "CIVILIAN"],
                0
            ],
        false]
    ],
    {
        params ["_args", "_pos"];
        _args params ["_sideStr"];
        _pos params ["_modulePos"];

        private _near = nearestObjects [_modulePos, ["Man", "Car", "Tank", "Air", "Ship", "Motorcycle"], 60];
        private _tgt = objNull;
        {
            if (alive _x) exitWith { _tgt = _x; };
        } forEach _near;

        if (isNull _tgt) exitWith { systemChat "No unit or vehicle nearby to tag."; };

        [_tgt, _sideStr] call Waldo_fnc_Tracker;
        systemChat format ["Signal tracker planted (%1).", _sideStr];
    },
    {},
    [_modulePos]
] call zen_dialog_fnc_create;

/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: prompts the curator for an EMP radius and duration, then detonates an
 * electromagnetic pulse at the module position (Waldo_fnc_EMP). The pulse is server-authoritative;
 * this just gathers the parameters and forwards them.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module
 * 1: objectPos <OBJECT> - object the module was dropped on (unused)
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenEMP;
 *
 * Public: No
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", "_objectPos"];

[
    "EMP Detonation",
    [
        ["SLIDER", ["Radius (m)", "Effect radius of the pulse."], [25, 1000, 150, 0], false],
        ["SLIDER", ["Duration (s)", "How long electronics stay down."], [5, 300, 30, 0], false]
    ],
    {
        params ["_args", "_pos"];
        _args params ["_radius", "_duration"];
        _pos params ["_modulePos"];
        [_modulePos, _radius, _duration, player] remoteExecCall ["Waldo_fnc_ZenEMPServer", 2];
        diag_log format ["[WMP EW] EMP module requested radius=%1 duration=%2 position=%3", _radius, _duration, _modulePos];
    },
    {},
    [_modulePos]
] call zen_dialog_fnc_create;

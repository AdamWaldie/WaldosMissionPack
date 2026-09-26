/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: prompts the curator for an EMP radius and duration, then detonates an
 * electromagnetic pulse at the module position (Waldo_fnc_EMP). The pulse is server-authoritative;
 * this just gathers the parameters and forwards them.
 * Locality and authority: Curator interface collects the inputs; the server validates and starts
 * the pulse at the chosen module position.
 * Repeat/JIP: Each accepted request starts a distinct pulse; the module dialog stores no local
 * handler or JIP state.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module
 * 1: objectPos <OBJECT> - object the module was dropped on (unused)
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenEMP;
 * Return Value: Nothing useful; the dialog submits asynchronously.
 * Current caller: ZEN EMP module registration.
 * Result: The curator can request an EMP with the selected radius and duration.
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

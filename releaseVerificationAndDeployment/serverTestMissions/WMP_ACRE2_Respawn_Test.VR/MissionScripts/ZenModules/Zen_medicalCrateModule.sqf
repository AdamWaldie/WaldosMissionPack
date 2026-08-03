/*
 * Author: WaldoTheWarfighter
 * Zeus "Waldos Medical Crate" module - spawns a medical supply crate (optionally a field hospital)
 * via a ZEN dialog. Registered as Waldo_fnc_ZenMedicalSpawner.
 *
 * Arguments:
 * 0: _modulePos <POSITION> - where to spawn the crate
 * 1: _objectPos <OBJECT> - the Zeus module object
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [getPos _logic, _logic] call Waldo_fnc_ZenMedicalSpawner;
 */

params ["_modulePos", "_objectPos"];

[
    "Waldos Medical Crate",
    [
        ["SLIDER:PERCENT", ["Supply size", "Regulate the total amount of supplies in the crate"], [0, 1, 2], false],
        ["CHECKBOX", ["Set as Field Hospital", "Set this crate to act as field hospital"], true, false]
    ],
    {
        params ["_arg", "_pos"];
        _arg params ["_size","_fieldHopsital"];
        _pos params ["_modulePos"];

        ["MEDICAL", _modulePos, [_size, _fieldHopsital], player]
            remoteExecCall ["Waldo_fnc_ZenSpawnCrateServer", 2];
    },
    {},
    [_modulePos]
] call zen_dialog_fnc_create;

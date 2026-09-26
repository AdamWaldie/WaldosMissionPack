/*
 * Author: WaldoTheWarfighter
 * Zeus "Waldos Medical Crate" module - spawns a medical supply crate (optionally a field hospital)
 * via a ZEN dialog. Registered as Waldo_fnc_ZenMedicalSpawner.
 * Locality and authority: Opens on the curator's interface; the submitted settings go to the
 * authenticated server crate spawner.
 * Repeat/JIP: Each accepted submission creates a new crate. The server registers its cargo and
 * enabled handling for joining players.
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
 * Current caller: ZEN "Waldos Medical Crate" module registration.
 * Result: The curator chooses crate size and optional field-hospital role before server spawn.
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

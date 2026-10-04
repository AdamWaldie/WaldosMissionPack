/*
 * Author: WaldoTheWarfighter
 * Opens the curator's supply-crate dialog. The server spawns the chosen crate from the configured
 * side's mission equipment pool after the curator submits its size and contents options.
 * Locality and authority: Curator interface opens the dialog; Waldo_fnc_ZenSpawnCrateServer
 * validates the request and creates the crate on the server.
 * Repeat/JIP: Every accepted submission creates a new crate; its cargo and handling state are
 * registered for joining clients by the server spawn path.
 *
 * Arguments:
 * 0: modulePos <POSITION>
 * 1: objectPos <OBJECT>
 *
 * Example:
 * [_modulePos, _moduleObject] call Waldo_fnc_ZenSupplySpawner;
 * Return Value: Nothing useful; the dialog opens asynchronously.
 * Current caller: ZEN "Waldos Supply Crate" module registration.
 * Result: The curator chooses size, content and side before the server spawns the crate.
 *
 * Public: No
 */

params ["_modulePos", "_objectPos"];

[
    "Waldos Supply Crate", 
    [
        ["SLIDER:PERCENT", ["Supply size", "Regulate the total amount of supplies in the crate"], [0, 1, 2], false],
        ["CHECKBOX", ["Add Equipment And Weapons", "Set this crate to include weapons, weapon attachments and wearables"], true, false],
        ["CHECKBOX", ["Add Launchers And Launcher Ammo", "Set this crate to also provide launchers and their ammo"], true, false],
        ["COMBO",["Side To Draw Contents From","Select the side (WEST,EAST,INDEPENDANT,CIVILLIAN) from which to draw equipment from"],
            [
                [
                    west,
                    east,
                    independent,
                    civilian
                ],
                [
                    "BLUFOR",
                    "OPFOR",
                    "INDFOR",
                    "CIVILIAN"
                ],
                0
            ],
        false]
    ],
    {
        params ["_arg", "_pos"];
        _arg params ["_size","_weaponsAttachmentsUniforms","_launchersAndAmmo","_suppliesFromside"];
        _pos params ["_modulePos"];


        ["SUPPLY", _modulePos, [_size, _suppliesFromside, _weaponsAttachmentsUniforms, _launchersAndAmmo], player]
            remoteExecCall ["Waldo_fnc_ZenSpawnCrateServer", 2];
    },
    {},
    [_modulePos]
] call zen_dialog_fnc_create;

/*
 * Author: Waldo
 * This module function spawn a supply crate, based on player weapon magazines.
 *
 * Arguments:
 * 0: modulePos <POSITION>
 * 1: objectPos <OBJECT>
 *
 * Example:
 * [getPos logic, this] call Waldo_fnc_CreateSupplyCrate;
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


        _crateClass = "B_CargoNet_01_ammo_F";

        if (isNil Logi_SupplyBoxClass) then {
            _crateClass = Logi_SupplyBoxClass;
        };

        _supCrate = _crateClass createVehicle _modulePos;

        [_supCrate, _size, _suppliesFromside, _weaponsAttachmentsUniforms, _launchersAndAmmo] call Waldo_fnc_SupplyCratePopulate;
        
        [_supCrate, -1, 1, true, true] call Waldo_fnc_SetCargoAttributes;
        
        // Add object to Zeus
        [{
            _this call ace_zeus_fnc_addObjectToCurator;
        }, _supCrate] call CBA_fnc_execNextFrame;
    },
    {},
    [_modulePos]
] call zen_dialog_fnc_create;
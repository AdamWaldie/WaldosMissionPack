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
        ["CHECKBOX", ["Only Ammo And Launchers", "Set this crate to only provide Ammunition and launchers, as opposed to equipment as well"], true, false],
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
        _arg params ["_size","_fullService","_suppliesFromside"];
        _pos params ["_modulePos"];


        _crateClass = "B_CargoNet_01_ammo_F";

        if (isNil Logi_SupplyBoxClass) then {
            _crateClass = Logi_SupplyBoxClass;
        };

        _supCrate = _crateClass createVehicle _modulePos;

        [_supCrate, _size, _suppliesFromside, !_fullService] call Waldo_fnc_SupplyCratePopulate;

        [_supCrate, 1] call ace_cargo_fnc_setSize;
        [_supCrate, true] call ace_dragging_fnc_setDraggable;
        [_supCrate, true] call ace_dragging_fnc_setCarryable;
        
        // Add object to Zeus
        [{
            _this call ace_zeus_fnc_addObjectToCurator;
        }, _supCrate] call CBA_fnc_execNextFrame;
    },
    {},
    [_modulePos]
] call zen_dialog_fnc_create;
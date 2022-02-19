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
        ["SLIDER:PERCENT", ["Supply size", "Regulate the total amount of supplies in the crate"], [0, 1, 2], false]
    ], 
    {
        params ["_arg", "_pos"];
        _arg params ["_size"];
        _pos params ["_modulePos"];

        private _crate = "B_CargoNet_01_ammo_F" createVehicle _modulePos;
        
        [_crate, _size] call Waldo_fnc_SupplyCratePopulate;

        // Change ace characteristics of crate
        [_crate, 1] call ace_cargo_fnc_setSize;
        [_crate, true] call ace_dragging_fnc_setDraggable;
        [_crate, true] call ace_dragging_fnc_setCarryable;

        // Add object to Zeus
        [{
            _this call ace_zeus_fnc_addObjectToCurator;
        }, _crate] call CBA_fnc_execNextFrame;
    },
    {},
    [_modulePos]
] call zen_dialog_fnc_create;
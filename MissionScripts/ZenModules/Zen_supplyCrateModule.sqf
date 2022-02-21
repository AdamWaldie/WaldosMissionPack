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


        _crateClass = "B_CargoNet_01_ammo_F";

        if (isNil Logi_SupplyBoxClass) then {
            _crateClass = Logi_SupplyBoxClass;
        };

        _supCrate = _crateClass createVehicle _modulePos;

        [_supCrate, _size] call Waldo_fnc_SupplyCratePopulate;

        // Add object to Zeus
        [{
            _this call ace_zeus_fnc_addObjectToCurator;
        }, _supCrate] call CBA_fnc_execNextFrame;
    },
    {},
    [_modulePos]
] call zen_dialog_fnc_create;
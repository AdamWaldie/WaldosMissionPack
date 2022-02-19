params ["_modulePos", "_objectPos"];

[
    "Waldos Medical Crate", 
    [
        ["SLIDER:PERCENT", ["Supply size", "Regulate the total amount of supplies in the crate"], [0, 1, 1], false],
        ["CHECKBOX", ["Set as Field Hospital", "Set this crate to act as field hospital"], true, false]
    ], 
    {
        params ["_arg", "_pos"];
        _arg params ["_size","_fieldHopsital"];
        _pos params ["_modulePos"];

        private _crate = "C_IDAP_supplyCrate_F" createVehicle _modulePos;
        
        [_crate, _fieldHopsital, _size] call Waldo_fnc_MedicalCratePopulate;

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
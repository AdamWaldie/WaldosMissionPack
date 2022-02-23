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

        _crateClass = "C_IDAP_supplyCrate_F";
        if (isNil Logi_MedicalBoxClass) then {
            _crateClass = Logi_MedicalBoxClass;
        };
        
        _medCrate = _crateClass createVehicle _modulePos;

        [_medCrate, _fieldHopsital, _size] call Waldo_fnc_MedicalCratePopulate;

        [_medCrate, 1] call ace_cargo_fnc_setSize;
        [_medCrate, true] call ace_dragging_fnc_setDraggable;
        [_medCrate, true] call ace_dragging_fnc_setCarryable;

        // Add object to Zeus
        [{
            _this call ace_zeus_fnc_addObjectToCurator;
        }, _medCrate] call CBA_fnc_execNextFrame;
    },
    {},
    [_modulePos]
] call zen_dialog_fnc_create;
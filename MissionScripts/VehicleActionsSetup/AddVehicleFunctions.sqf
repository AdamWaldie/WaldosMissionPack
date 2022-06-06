/*
 * Author: Waldo
 * This function apply specific functions to classes of vehicle (limited use - primarily for auto applying "getoutside" to RHS and CUP helos
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Example:
 * [_vehicle] call Waldo_fnc_AddVehicleFunctions;
 */
params [["_vehicle", objNull, [objNull]]];

if (_vehicle iskindOf "man") exitWith {};
if (!isNil{_vehicle getVariable "Waldo_Vehicle_Functions_Added"}) exitWith {};

private _vehicleType = typeOf _vehicle;

if (_vehicle iskindOf "Heli_Transport_01_base_F") then {
    [_vehicle] call Waldo_fnc_AddExitActions;
};
if (_vehicle iskindOf "RHS_UH60_Base") then {
    switch (_vehicleType) do {
        case "RHS_UH60M_MEV2_d";
        case "RHS_UH60M_MEV_d";
        case "RHS_UH60M_MEV2";
        case "RHS_UH60M_MEV";
        case "MED": {_vehicle setVariable ["ace_medical_isMedicalVehicle", true, true];};
        default {};
    };
};
if (_vehicle iskindOf "rhs_uh1h_base") then {
    [_vehicle] call Waldo_fnc_AddExitActions;
};
if (_vehicle iskindOf "RHS_UH1_Base") then {
    [_vehicle] call Waldo_fnc_AddExitActions;
};

if (_vehicle iskindOf "RHS_Mi24_base") then {
    [_vehicle] call Waldo_fnc_AddExitActions;
    //[_vehicle] call Waldo_fnc_AddStaticJump;
};

if (_vehicle iskindOf "RHS_Mi8_base") then {
    [_vehicle] call Waldo_fnc_AddStaticJump;
};

if (_vehicle iskindOf "Heli_Transport_02_base_F") then {
    [_vehicle] call Waldo_fnc_AddStaticJump;
};
// WIP for once I allow both systems
/*if (_vehicle iskindOf "RHS_C130J_Base") then {
    [_vehicle] call Waldo_fnc_AddStaticJump;
    [_vehicle] call Waldo_fnc_AddHaloJump;
};*/

if (_vehicle iskindOf "MRAP_01_base_F") then {
    [_vehicle, 4, 40, false, false] call Waldo_fnc_SetCargoAttributes;
    switch (_vehicleType) do {
        case "MED": {_vehicle setVariable ["ace_medical_isMedicalVehicle", true, true];};
        default {};
    };
};

if (_vehicle iskindOf "Truck_01_base_F") then {
    switch (_vehicleType) do {
        case "rhsusf_M1230a1_usarmy_wd";
        case "rhsusf_M1230a1_usarmy_d";
        case "MED": {_vehicle setVariable ["ace_medical_isMedicalVehicle", true, true];};
        default {};
    };
};

if (_vehicle iskindOf "rhsusf_stryker_base") then {
    switch (_vehicleType) do {
        case "MED": {_vehicle setVariable ["ace_medical_isMedicalVehicle", true, true];};
        default {};
    };
};

_vehicle setVariable ["Waldo_Vehicle_Functions_Added", true];
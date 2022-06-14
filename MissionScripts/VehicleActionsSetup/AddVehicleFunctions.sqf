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

// Get Halo HALO & STATIC Variables
//Get STATIC Altitude & CHUTE Arguments
private _staticMinAlt = missionNamespace getVariable "WALDO_STATIC_MINALTITUDE";
if (isNil "_staticMinAlt") then
{
    missionNamespace setVariable ["WALDO_STATIC_MINALTITUDE", 180];
    _staticMinAlt = 180;
};
private _staticMaxAlt = missionNamespace getVariable "WALDO_STATIC_MAXALTITUDE";
if (isNil "_staticMaxAlt") then
{
    missionNamespace setVariable ["WALDO_STATIC_MAXALTITUDE", 350];
    _staticMaxAlt = 350;
};
private _staticMaxSpd = missionNamespace getVariable "WALDO_STATIC_MAXSPEED";
if (isNil "_staticMaxSpd") then
{
    missionNamespace setVariable ["WALDO_STATIC_MAXSPEED", 310];
    _staticMaxSpd = 310;
};
private _staticChute = missionNamespace getVariable "WALDO_STATIC_STATICCHUTE";
if (isNil "_staticChute") then
{
    missionNamespace setVariable ["WALDO_STATIC_STATICCHUTE", "rhs_d6_Parachute"];
    _staticChute = "rhs_d6_Parachute";
};
private _haloAlt = missionNamespace getVariable "WALDO_PARA_HALOALTITUDE";
//Get HALO Altitude & CHUTe Arguments
if (isNil "_haloAlt") then
{
    missionNamespace setVariable ["WALDO_PARA_HALOALTITUDE", 1000];
    _haloAlt = 1000;
};
private _haloChute = missionNamespace getVariable "WALDO_PARA_HALOCHUTE";
if (isNil "_haloChute") then
{
    missionNamespace setVariable ["WALDO_PARA_HALOCHUTE", "B_Parachute"];
    _haloChute = "B_Parachute";
};

// Get type of vehicle
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
    [_vehicle, _staticMinAlt, _staticMaxAlt, _staticMaxSpd, _staticChute] call Waldo_fnc_AddStaticJump;
    [_vehicle] call Waldo_fnc_JumpSettingsCheck;
};

if (_vehicle iskindOf "RHS_Mi8_base") then {
    [_vehicle, _staticMinAlt, _staticMaxAlt, _staticMaxSpd, _staticChute] call Waldo_fnc_AddStaticJump;
    [_vehicle] call Waldo_fnc_JumpSettingsCheck;
};

if (_vehicle iskindOf "Heli_Transport_02_base_F") then {
    [_vehicle, _staticMinAlt, _staticMaxAlt, _staticMaxSpd, _staticChute] call Waldo_fnc_AddStaticJump;
    [_vehicle] call Waldo_fnc_JumpSettingsCheck;
};
// WIP for once I allow both systems
if (_vehicle iskindOf "RHS_C130J_Base") then {
    /*
    Waldo_fnc_AddHaloJump Arguments:
    0: Vehicle             <OBJECT>
    1: Minimum altitude    <NUMBER> (Optional) (Default; 5000)
    4: Chute Vehicle Class <OBJECT> (Optional) (Default; "B_Parachute")
    */
    [_vehicle, _haloAlt, _haloChute] call Waldo_fnc_AddHaloJump;
    /*
    Waldo_fnc_AddStaticJump Arguments:
    0: Vehicle             <OBJECT>
    1: Minimum altitude    <NUMBER> (Optional) (Default; 180)
    2: Maximum altitude    <NUMBER> (Optional) (Default; 350)
    3: Maximum speed       <NUMBER> (Optional) (Default; 310)
    4: Chute Vehicle Class <OBJECT> (Optional) (Default; "rhs_d6_Parachute") Requires RHS, respecify alternative if required. (NonSteerable_Parachute_F is vanilla)
    */
    [_vehicle, _staticMinAlt, _staticMaxAlt, _staticMaxSpd, _staticChute] call Waldo_fnc_AddStaticJump;
    // leave this one as is.
    [_vehicle] call Waldo_fnc_JumpSettingsCheck;
};


if (_vehicle iskindOf "B_T_VTOL_01_infantry_F") then {
    private _haloAlt = missionNamespace getVariable "WALDO_PARA_HALOALTITUDE";
    /*
    Waldo_fnc_AddHaloJump Arguments:
    0: Vehicle             <OBJECT>
    1: Minimum altitude    <NUMBER> (Optional) (Default; 5000)
    4: Chute Vehicle Class <OBJECT> (Optional) (Default; "B_Parachute")
    */
    [_vehicle, _haloAlt, _haloChute] call Waldo_fnc_AddHaloJump;
    /*
    Waldo_fnc_AddStaticJump Arguments:
    0: Vehicle             <OBJECT>
    1: Minimum altitude    <NUMBER> (Optional) (Default; 180)
    2: Maximum altitude    <NUMBER> (Optional) (Default; 350)
    3: Maximum speed       <NUMBER> (Optional) (Default; 310)
    4: Chute Vehicle Class <OBJECT> (Optional) (Default; "rhs_d6_Parachute") Requires RHS, respecify alternative if required. (NonSteerable_Parachute_F is vanilla)
    */
    [_vehicle, _staticMinAlt, _staticMaxAlt, _staticMaxSpd, _staticChute] call Waldo_fnc_AddStaticJump;
    // leave this one as is.
    [_vehicle] call Waldo_fnc_JumpSettingsCheck;
};

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
/*
 * Author: WaldoTheWarfighter
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

// Recovery controls belong to the physical vehicle, not to every player's
// action menu. Each interface installs its own local action once.
if (_vehicle isKindOf "LandVehicle" && {hasInterface}) then {
    [_vehicle] call Waldo_fnc_SetupVehicleUprightLocal;
};

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
// The RHS chute above silently fails to install (Waldo_fnc_AddStaticJump exits early on an unknown
// class) on any mission without RHS loaded - fall back to the vanilla fixed-wing chute so a non-RHS
// mission's auto-detected static-line action actually appears instead of just disappearing.
if !(isClass (configFile >> "CfgVehicles" >> _staticChute)) then {_staticChute = "NonSteerable_Parachute_F";};
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

// Jump-capable auto-detected classes: a mission maker can always take manual control of any of
// these same aircraft with Waldo_fnc_VehicleJumpSetup, Waldo_fnc_ParadropQuickFlightSetup or the
// Dynamic Drop Zone system (Waldo_fnc_ParadropCreateDropZone / the ZEN module) - all three mark the
// aircraft with Waldo_Paradrop_ManuallyConfigured before installing their own static/HALO envelope.
// This auto-detection must not then fight that explicit setup with its own mission-global defaults
// (that conflict, not just being redundant, is a real bug: this block's hardcoded static chute
// fallback is the RHS class "rhs_d6_Parachute", which silently fails to install - leaving only
// HALO active - on any non-RHS mission, exactly the shipped vanilla example compositions). Defer
// past WALDO_INIT_COMPLETE so an object's own init-field setup call (which runs synchronously at
// vehicle creation, before this deferred check) has always had the chance to set the flag first.
if (
    _vehicle iskindOf "RHS_Mi24_base"
    || {_vehicle iskindOf "RHS_Mi8_base"}
    || {_vehicle iskindOf "Heli_Transport_02_base_F"}
    || {_vehicle iskindOf "RHS_C130J_Base"}
    || {_vehicle iskindOf "B_T_VTOL_01_infantry_F"}
) then {
    if (_vehicle iskindOf "RHS_Mi24_base") then {[_vehicle] call Waldo_fnc_AddExitActions;};
    [_vehicle, _staticMinAlt, _staticMaxAlt, _staticMaxSpd, _staticChute, _haloAlt, _haloChute] spawn {
        params ["_vehicle", "_staticMinAlt", "_staticMaxAlt", "_staticMaxSpd", "_staticChute", "_haloAlt", "_haloChute"];
        waitUntil {sleep 0; missionNamespace getVariable ["WALDO_INIT_COMPLETE", false] || {isNull _vehicle}};
        if (isNull _vehicle || {_vehicle getVariable ["Waldo_Paradrop_ManuallyConfigured", false]}) exitWith {};
        // C130J and the Blackfish support both HALO and static-line jumps; their hold actions have
        // mutually-exclusive altitude conditions so only the valid one shows at a time.
        if (_vehicle iskindOf "RHS_C130J_Base" || {_vehicle iskindOf "B_T_VTOL_01_infantry_F"}) then {
            [_vehicle, _haloAlt, _haloChute] call Waldo_fnc_AddHaloJump;
        };
        [_vehicle, _staticMinAlt, _staticMaxAlt, _staticMaxSpd, _staticChute] call Waldo_fnc_AddStaticJump;
        [_vehicle] call Waldo_fnc_JumpSettingsCheck;
    };
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

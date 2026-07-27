/*
This function apply the Jump Functionality To Aircraft.

C130J from RHS is automatically handled with the below parameters

THIS FEATURE IS PRESENTLY CONFLICTING WITH THE VEHICLE ACTION HANDLER, AND SHOULD ONLY BE CALLED ON VEHICLES NOT COVERED UNDER THAT.

Arguments:
0: Vehicle <OBJECT>

Example:
[this] call Waldo_fnc_VehicleJumpSetup;
*/

params ["_vehicle"];


//Basic prevention of sillyness
if (_vehicle iskindOf "man") exitWith {};

// No Restrictions. Mission Makers please use responsibly!
// As called from unit init, enviroment is unscheduled, so we force a schedule with spawn, and add actions after units ingame. Not  efficent, but easier to use / more adaptable for the end user.
_schdenvirohndlr = [_vehicle] spawn {
    params ["_vehicle"];
    waitUntil { missionNamespace getVariable ["WALDO_INIT_COMPLETE",false] };
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
    /*
    Waldo_fnc_AddHaloJump Arguments:
    0: Vehicle             <OBJECT>
    1: Minimum altitude    <NUMBER> (Optional) (Default; 5000)
    4: Chute Vehicle Class <OBJECT> (Optional) (Default; "B_Parachute")
    */
    [_vehicle, _haloAlt, _haloChute] call Waldo_fnc_AddHaloJump;

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
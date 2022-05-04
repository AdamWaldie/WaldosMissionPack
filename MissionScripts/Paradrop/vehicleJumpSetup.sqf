/*
This function apply the Jump Functionality To Aircraft

Arguments:
0: Vehicle <OBJECT>

Example:
[this] call Waldo_fnc_VehicleJumpSetup;
*/

params ["_vehicle"];

diag_log "Vehicle Setup Reached";

//Basic prevention of sillyness
if (_vehicle iskindOf "man") exitWith {};

// No Restrictions. Mission Makers please use responsibly!
// As called from unit init, enviroment is unscheduled, so we force a schedule with spawn, and add actions after units ingame. Not  efficent, but easier to use / more adaptable for the end user.
_schdenvirohndlr = [_vehicle] spawn {
    params ["_vehicle"];
    diag_log "Vehicle Setup Reached";
    waitUntil { missionNamespace getVariable ["WALDO_INIT_COMPLETE",false] };
    /*
    Waldo_fnc_AddHaloJump Arguments:
    0: Vehicle             <OBJECT>
    1: Minimum altitude    <NUMBER> (Optional) (Default; 5000)
    4: Chute Vehicle Class <OBJECT> (Optional) (Default; "B_Parachute")
    */
    [_vehicle, 1000, "B_Parachute"] call Waldo_fnc_AddHaloJump;
    /*
    Waldo_fnc_AddStaticJump Arguments:
    0: Vehicle             <OBJECT>
    1: Minimum altitude    <NUMBER> (Optional) (Default; 180)
    2: Maximum altitude    <NUMBER> (Optional) (Default; 350)
    3: Maximum speed       <NUMBER> (Optional) (Default; 310)
    4: Chute Vehicle Class <OBJECT> (Optional) (Default; "rhs_d6_Parachute") Requires RHS, respecify alternative if required. (NonSteerable_Parachute_F is vanilla)
    */
    [_vehicle, 180, 350, 310, "rhs_d6_Parachute"] call Waldo_fnc_AddStaticJump;
    // leave this one as is.
    [_vehicle] call Waldo_fnc_JumpSettingsCheck;
};
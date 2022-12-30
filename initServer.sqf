/*
If you are utilising the Virtual Logistics Quartermaster (initQuartermaster.sqf & LogiBoxes.sqf) You can set custom boxes for both Medical & Supply boxes.
By default, leaving these unchanged, will provide players with the Default ACE Medical/Vanilla Medical box & Vanilla Supply box. you do not need to change these

You will need to find the classname of the box you are wanting to use, and place it with the quotation marks in where dennoted below;

missionNamespace setVariable ["SupplyBoxClass", "PUTCLASSNAMEHERE", true];

*/

//Supply Box Classname MissionNameSpace Declaration
missionNamespace setVariable ["Logi_SupplyBoxClass", "B_supplyCrate_F",true];
//Logi_SupplyBoxClass = "B_supplyCrate_F";
//Medical Box Classname MissionNameSpace Declaration
if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then {
    missionNamespace setVariable ["Logi_MedicalBoxClass", "ACE_medicalSupplyCrate_advanced",true];
} else {
    missionNamespace setVariable ["Logi_MedicalBoxClass", "C_IDAP_supplyCrate_F",true];
};


/*
PARADROP SCRIPTS

MissionScripts\Paradrop has all the paradrop related functions. Waldos_functions.sqf under Paradrop display the function names.

For basic usage, most "Plane" class assets, and some Helicopters have static line &/or HALO jump capabilities added automatically. The C130J from RHS and its inherritants also have full use of these systems.

You can also tweak the below variables to supply custom parachute classes, as well as change the requirements for HALO & Static Line jumps to be availble to perform. 

This affects both the automatically added vehicles, and those you manually add via:
[this] call Waldo_fnc_VehicleJumpSetup;

*/
//Static Line Variables
//Static Minimum Altitude
missionNamespace setVariable ["WALDO_STATIC_MINALTITUDE", 180, true];
//Static Maximum Altitude
missionNamespace setVariable ["WALDO_STATIC_MAXALTITUDE", 350, true];
//Static Maximum Speed
missionNamespace setVariable ["WALDO_STATIC_MAXSPEED", 310, true];
//Static Line Parachute Class
missionNamespace setVariable ["WALDO_STATIC_STATICCHUTE", "rhs_d6_Parachute", true];

//HALO Jump Variables
//HALO Minimum Altitude
missionNamespace setVariable ["WALDO_PARA_HALOALTITUDE", 1000, true];
//HALO Parachute Class
missionNamespace setVariable ["WALDO_PARA_HALOCHUTE", "B_Parachute", true];

/*

Mission.sqm based supply system

This searches the Mission.sqm for playable characters on the side defined by the parameter. It grabs their compliment of weapons, ammo, clothing and items, gets uniques and returns a unique 2D Array of the results.

These results are then globaly synced, for use in the ZEN resupply boxes & to create ACE Arsenals with equipment limited to that pre-existing in the mission.sqm

IMPORTANT: YOU MUST EDIT THE LOADOUTS OF PLACED UNITS WITH AN ARSENAL OF SOME DESCRIPTION FOR THIS TO WORK, VANILLA UNIT LOADOUTS WILL NOT SUFFICE!

*/

[] call Waldo_fnc_SideBaseLoadoutSetup;
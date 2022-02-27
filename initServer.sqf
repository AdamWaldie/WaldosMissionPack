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

Mission.sqm based supply system

This searches the Mission.sqm for playable characters on the side defined by the parameter. It grabs their compliment of weapons, ammo, clothing and items, gets uniques and returns a unique 2D Array of the results.

These reesults are then globaly synced, for use in the ZEN resupply boxes & to create ACE Arsenals with equipment limited to that pre-existing in the mission.sqm.

Parameters:
- "West"
- "East"
- "Independent"
- "Civilian"

*/

loadoutArray = ["West"] call Waldo_fnc_MissionSQMLookup; 
missionNamespace setVariable ["Logi_MissionSQMArray", loadoutArray,true];
//Set Value To Say That Mission Scan Is Complete
missionNamespace setVariable ["Logi_MissionScanComplete", true,true];

/* 
Mobile Headquarters Script

A script which allows for the creation of a command post, acting as a respawn position, and logistics quartermaster if desired.

This allows a number of objects, as defined in a Eden Editor layer, to be attached to a vehicle, and "deployed"/"undeployed" on request when in a desired location.

When setup in initServer.sqf:
- Objects defined in the named layer are attached relative to their position to the target vehicle.
- Those same objects are then hidden globally.

When deployed the following occurs:
- Objects defined in the named layer are set as visible.
- A respawn position is enabled around the vehicle in quesiton.
- (Optional) A logistics quartermaster from the logistics module is added to the vehicle.
- (choice of one) Deployment sounds are played (old style wood & modern day construction noises)

When Un-deployed the following occurs:
- Objects defined in the named layer are set as invisible.
- The Mobile HQ Respawn position is disabled.
- (Optional) The Logistics Quartermaster is removed.
- (choice of one) Un-Deployment sounds are played (old style wood & modern day construction noises)

This is done in two parts, with the MHQ layer setup being done here, while the actions themselves are applied in the init.sqf

Parameters for Waldo_fnc_ServerSetupMHQ: (The Function Call Below)
_MHQVariableName - Variable name of the vehicle being used as the mHQ 
_layerName - the name of the eden editor layer which houses the objects which make up the Mobile Headquarters additional objects. THIS SHOULD NOT INCLUDE THE VEHICLE ITSELF! Quotation Marks required ("").

e.g.

From initServer.sqf:

[variableNameofMHQ,"layerName"] call Waldo_fnc_ServerSetupMHQ;

*/

[MobileHQ,"MobileHeadQuartersLayer"] call Waldo_fnc_ServerSetupMHQ;

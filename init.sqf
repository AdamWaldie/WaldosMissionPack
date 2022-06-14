/*

This file is called in multiplayer, as the loading screen is transitioning into the game. It runs on all connected clients, and the server.

Below is the setup for the majority of QOL scripts in this pack.

Enable/disable them as it suits you.

*/

//Lighting Setup Engine - Optional
//"LightShafts" ppEffectAdjust [0.9, 0.8, 0.9, 0.8];

/* 

Player Makers Script (Best utilised When ACE Markers Are Not An Option)

Parameters >>
	"players" - Will show players.
	"ais" - Will show AIs.
	"allsides" - Will show all sides not only the units on player's side.
	"all" - Enable all of the above.
	"stop" - Stop the script.

Example code - 0 = ["players"] execVM "player_markers.sqf";

*/
//0 = ["players"] execVM "MissionScripts\ThirdPartyScripts\player_markers.sqf";


/*
Werthless Headless Client call

Requires:
Virtual Headless Client Entity

Reccomended to leave call as is. Information regarding HC can be found in the associated third party script.
*/
//[true,30,false,true,30,10,true,[]] execVM "MissionScripts\ThirdPartyScripts\WerthlesHeadless.sqf";


//Zeus Enhanced Modules setup (comment out to disable)
[] call Waldo_fnc_ZenInitModules;

//Set ace namespace variables for maximum drag/carryweights (Tune these so that you can carry/drag your logistics boxes ingame)
ACE_maxWeightDrag = 10000;
ACE_maxWeightCarry = 6000;

/*
//Initilise ACRE 2 Radios
//Setup Array and Callsign list [EDIT THIS SECTION FOR YOUR MISSION!] - IF YOU DO NOT HAVE ACRE 2 ENABLED, The function will exit automatically.
private _UnitRadioSetups = [
    //In format ["Callsign",343RadioChannel,152RadioChannel,148RadioChannel,117FRadioChannel]
    // The last line should not have a , at the end.
    // Callsigns should be in "", and radio channels should be without "".
    ["Odin",4,2,3,4],
    ["Thor",1,2,3,4],
    ["Loki",2,2,3,4],
    ["Mimir",3,2,3,4],
    ["Valkyrie",5,2,3,4],
    ["High Command",6,2,3,4]
];
[_UnitRadioSetups] call Waldo_fnc_ACRE2Init;
*/


/*
If you are utilising the Virtual Logistics Quartermaster (initQuartermaster.sqf & LogiBoxes.sqf) You can set custom boxes for both Medical & Supply boxes.
By default, leaving these unchanged, will provide players with the Default ACE Medical/Vanilla Medical box & Vanilla Supply box. you do not need to change these

You will need to find the classname of the box you are wanting to use, and place it with the quotation marks in where dennoted below;

missionNamespace setVariable ["SupplyBoxClass", "PUTCLASSNAMEHERE", true];

YOU CAN SPECIFY CUSTOM BOXES FOR MEDICAL & AMMO BOXES IN initServer.sqf

*/


//AI Tweak setup
// These commands initiate Waldos AI Tweaks. It is an Either/OR situation, where the DAY OR NIGHT mode can be active per mission.
// Daytime Mission parameter - uncomment this for daytime AI values.
"DAY" call Waldo_fnc_AITweak;
// Nightime Mission - uncomment this for nightime AI values.
//"NIGHT" call Waldo_fnc_AITweak;


/*
Vehicle function eventhandler

This adds vehicle functions to affected vehicles:
- Get out on specfic side. Only affects RHS gear so far.
- Auto added medical/logistics status to vehicles.  Only affects RHS gear so far.
- HALO / Static line [WIP] Only affects RHS gear so far.

*/
call Waldo_fnc_InitVehicles;

/* 
Introduction Text - Cool Introduction stuff like location, date, time and mission name and locale

When left with no parameters, as below, the script autogenerates the location based on the terrain name, and the mission title from the description.ext 
You can optionally define replacements for the title & location, as is demonstrated in the trigger in the exemplar mission. 
*/
[] call Waldo_fnc_InfoText;


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

This is done in two parts, with the MHQ layer setup being done in initServer.sqf and the actions to activate/deactivate the MHQ happening here.

IMPORTANT NOTE FOR THIS TO WORK:
 - DO NOT DISABLE SIMULATION FOR THE HELIPAD 
 - DO NOT APPLY THE STARTER CRATE SCRIPT TO THE MHQ

Parameters for Waldo_fnc_SetupMHQActions: (The Function Call Below)
Parameters:
_MHQ - Vehicle or Object to use as the Mobile headquarters
_helipadSpawnPoint - Name of the invisible helipad you wish to use as the respawn position & logistics spawning position.
_side - Side you want the respawn positon to work for | Options: west,east,independent,civillian
_UseModernConsturctionAudio - boolean (true/false) | Options: True = Modern construction Noises, False = Old Wooden Sounding Construction Noises.
_logisticsSystemImplementation - boolean (true/false) | Options: True = Utilise Logistics System spawner, False = Do Not utilise logistics system spawner.

In order to use the logistics system, you must set _logisticsSystemImplementation = true in the parameters AND ensure that there is a base game helipad ("Land_HelipadEmpty_F") in the layer which contains the deployable objects.

e.g.

From initServer.sqf:

[variableNameofMHQ,"layerName",west] call Waldo_fnc_SetupMHQActions;

*/


/*

waldos Init Completion flag

======DO NOT TOUCH!=====

Allows scheduling of the following script packages:
- Starter crates
- Ace Limited Arsenals on objects placed in eden editor

Zeus modules & script spawned supply boxes are unaffected

*/
sleep 10; // Buffer cycles for other inits to be completed - should not be removed
//Wait until player is in control of themselves, and then, if INIT flag isnt already set, set it.
waitUntil {!isNull player && player == player};
private _firstPlayerIn = missionNamespace getVariable "WALDO_INIT_COMPLETE";
if (isNil "_firstPlayerIn") then
{
	missionNamespace setVariable ["WALDO_INIT_COMPLETE", true, true];
};
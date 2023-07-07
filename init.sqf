/*

This file is called in multiplayer, as the loading screen is transitioning into the game. It runs on all connected clients, and the server.

Below is the setup for the majority of QOL scripts in this pack.

Enable/disable them as it suits you.

*/

//Lighting Setup Engine - Optional
//"LightShafts" ppEffectAdjust [0.9, 0.8, 0.9, 0.8];

//Third Party Scripts (Look at mentioned file to enable 
//[] execVM "MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf";


//Zeus Enhanced Modules setup (comment out to disable)
[] call Waldo_fnc_ZenInitModules;

/*===========================================================================================================================*/

//Set ace namespace variables for maximum drag/carryweights (Tune these so that you can carry/drag your logistics boxes ingame)
ACE_maxWeightDrag = 10000;
ACE_maxWeightCarry = 6000;


/*===========================================================================================================================*/

/*
AI Tweak setup
These commands initiate Waldos AI Tweaks. It is an Either/OR situation, where the DAY OR NIGHT mode can be active per mission.
Daytime Mission parameter - uncomment this for daytime AI values.
*/
"DAY" call Waldo_fnc_AITweak;
// Nightime Mission - uncomment this for nightime AI values.
//"NIGHT" call Waldo_fnc_AITweak;


/*===========================================================================================================================*/


/*
ACRE 2 RADIO SETUP PARAMETERS

This section deals with setting up preset radio channels and marking out the pre-set channels to set player squads to.

You can set which squads are assigned to which of the channels you have chosen. Side does not matter here.

The format is as follows ["Squad Name",["ChannelSelection1","ChannelSelection2","ChannelSelection3"] where the Squad name is idential to the group name you picked earlier. 
ChannelSelection1 though 3 should match one channel in the LongRangeRadioChannel for the side of that squad. You can have up to three choices, 
however this is limited by the number of AN/PRC-152,AN/PRC-148 and AN/PRC-117F radios on that squad. 
You should enter channels based on the range required. E.g. Platoon Net followed by Air2Ground or Company Net.

AN/PRC-343 Radios are done automatically based on squad callsign and Numerical designations (if any).

ACRE CEOI in the map screen will note all channel assignments for referance.

*/

private _RadioSetups = [
    ["Viking-1-1",[1,5]],
	["Viking 5",[2,7]],
	["Viking 3.2",[3,2]],
	["Banshee",[4,1]]
];
[_RadioSetups] call Waldo_fnc_ACRE2Init;


/*===========================================================================================================================*/

/*
Vehicle function eventhandler

This adds vehicle functions to affected vehicles:
- Get out on specfic side. Only affects RHS gear so far.
- Auto added medical/logistics status to vehicles.  Only affects RHS gear so far.
- HALO / Static line [WIP] Only affects RHS gear so far.

*/
call Waldo_fnc_InitVehicles;

/*===========================================================================================================================*/

/* 
Introduction Text - Cool Introduction stuff like location, date, time and mission name and locale

When left with no parameters, as below, the script autogenerates the location based on the terrain name, and the mission title from the description.ext 
You can optionally define replacements for the title & location, as is demonstrated in the trigger in the exemplar mission.
*/
["",""] call Waldo_fnc_InfoText;

/*

waldos Init Completion flag

======DO NOT TOUCH!=====
*/
sleep 10; // Buffer cycles for other inits to be completed - should not be removed
//Wait until player is in control of themselves, and then, if INIT flag isnt already set, set it.
waitUntil {!isNull player && player == player};
private _firstPlayerIn = missionNamespace getVariable "WALDO_INIT_COMPLETE";
if (isNil "_firstPlayerIn") then
{
	missionNamespace setVariable ["WALDO_INIT_COMPLETE", true, true];
};
/*
Purpose: Mission Parameters for various QOL scripts.
Called From: init.sqf
Scope: All players within mission. (I am aware of the inefficacy, but this is easier on the missionmakers who do not program)
Execution time: Mission start (+/- 1 minute)
Author: Waldo
For: Rooster Teeth Gaming Community
License: Distributable and editable with proper attribution.

How to call:
From init.sqf

_ACRE2InitHandle = execvm "missionParameters.sqf";

This is done for you in mission packs.

This file is for mission makers to change based on their needs. Most scritps rely on the parameters here.

*/

//Lighting Setup Engine - Optional
//"LightShafts" ppEffectAdjust [0.9, 0.8, 0.9, 0.8];

//Zeus Enhanced Modules setup (comment out to disable)
[] call Waldo_fnc_ZenInit;

// Set ace namespace variables for maximum drag/carryweights
ACE_maxWeightDrag = 2000;
ACE_maxWeightCarry = 2000;

//Initilise ACRE 2 Radios
//Setup Array and Callsign list [EDIT THIS SECTION FOR YOUR MISSION!]
private _UnitRadioSetups = [
    //In format ["Callsign",343RadioChannel,152RadioChannel,148RadioChannel,117FRadioChannel]
    // The last line should not have a , at the end.
    // Callsigns should be in "", and radio channels should be without "".
    ["Odin",4,1,1,3],
    ["Thor",1,1,1,3],
    ["Loki",2,1,1,3],
    ["Mimir",3,1,1,3],
    ["Valkyrie",5,1,1,3],
    ["High Command",5,1,1,3]
];
//Make the call!
//[_UnitRadioSetups] call compile preprocessFileLineNumbers "MissionScripts\ACRE2Init.sqf"; -  Depreciated
[_UnitRadioSetups] call Waldo_fnc_ACRE2Init;

//AI Tweak setup
// These commands initiate Waldos AI Tweaks. It is an Either/OR situation, where the DAY OR NIGHT mode can be active per mission.
// Daytime Mission parameter - uncomment this for daytime AI values.
"DAY" call Waldo_fnc_AITweak;
// Nightime Mission - uncomment this for nightime AI values.
//"NIGHT" call Waldo_fnc_AITweak;

/* 
Introduction Text - Cool Introduction stuff like location, date, time and mission name and locale

When left with no parameters, as below, the script autogenerates the location based on the terrain name, and the mission title from the description.ext 
You can optionally define replacements for the title & location, as is demonstrated in the trigger in the exemplar mission. 
*/
[] call Waldo_fnc_InfoText;
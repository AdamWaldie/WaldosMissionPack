/*
Purpose: Mission Parameters for various QOL scripts.
Called From: init.sqf
Scope: All players within mission. (I am aware of the inefficacy, but this is easier on the missionmakers who do not program)
Execution time: Mission start (+/- 1 minute)
Author: Waldo
License: Distributable and editable with proper attribution.

How to call:
From init.sqf

This is done for you in mission packs.

This file is for mission makers to change based on their needs. Most scritps rely on the parameters here.

*/

//Lighting Setup Engine - Optional
//"LightShafts" ppEffectAdjust [0.9, 0.8, 0.9, 0.8];

//Zeus Enhanced Modules setup (comment out to disable)
[] call Waldo_fnc_ZenInitModules;

//Set ace namespace variables for maximum drag/carryweights (Tune these so that you can carry/drag your logistics boxes ingame)
ACE_maxWeightDrag = 10000;
ACE_maxWeightCarry = 6000;


//Initilise ACRE 2 Radios
//Setup Array and Callsign list [EDIT THIS SECTION FOR YOUR MISSION!]
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
Introduction Text - Cool Introduction stuff like location, date, time and mission name and locale

When left with no parameters, as below, the script autogenerates the location based on the terrain name, and the mission title from the description.ext 
You can optionally define replacements for the title & location, as is demonstrated in the trigger in the exemplar mission. 
*/
[] call Waldo_fnc_InfoText;


/*

waldos Init Completion flag

======DO NOT TOUCH!=====

Allows scheduling of the following script packages:
- Starter crates
- Ace Limited Arsenals on objects placed in eden editor

Zeus modules & script spawned supply boxes are unaffected

*/
waitUntil {!isNull player && player == player};
missionnamespace  setVariable ["WALDO_INIT_COMPLETE", true, true];

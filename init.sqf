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

/*
Waldos Economy Systems (Resource / Research / Build / Buy + Ground Command)

A pub-Zeus economy suite: define resources, capturable income zones and collectable crates,
run research at a Research Center, construct and upgrade buildings, and let players buy vehicles.
A trusted "Ground Command" controls spending. Everything is driven live from the Zeus menu
"Waldos Economy Systems" - no editor work required beyond enabling it.

Set the flag below to true to start the economy suite (runs on all machines; it self-branches
between the server authority loops and the client Zeus menu). It is OFF by default so missions
that do not use it pay no cost. You can also enable it without editing this file by dropping the
"[WMP] Waldos Economy Systems" composition (its object boots the suite from its own init).

To pre-configure the economy from the editor (a bundled LOW/MEDIUM/HIGH preset, a full exported
config string, or commitment mode) without opening Zeus, see the "Waldos Economy Systems"
setup block in initServer.sqf.

Full guide (easiest path first): https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems
*/
Waldo_Economy_Enable = false;
if (Waldo_Economy_Enable) then {
    [] spawn Waldo_fnc_EcoInit;
};

/*
Waldos Mini Games (table party games + interaction procedures)

Two complementary systems under one feature:

  1. Table games - a seated, multiplayer party-games engine with twelve games including Texas
     Hold'em, Five-Card Draw, Liar's Dice and Connect Four. Place any supported table object (a
     camping table by default) in Eden and players get actions to sit, vote and play. Runs on all
     machines (server authority + client UI) and is JIP-safe. This installer is repeat-safe.

  2. Interaction procedures - ten single-player field-equipment procedures that resolve to an
     authoritative outcome and can gate any object interaction (see Waldo_fnc_MiniGameInteraction
     / Waldo_fnc_BombDefuseSetup). They register on first use and are independent of this flag.

Set the flag to false if your mission uses no table games (the interaction challenges are
unaffected). Full guide: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games
*/
Waldo_MiniGames_Enable = true;
if (Waldo_MiniGames_Enable) then {
    [] call Waldo_fnc_MiniGamesInit;
};

/*
ACE Corpse Traps

Lets players consume a carried throwable to rig any corpse through ACE interaction. The exact
magazine is preserved, so vanilla and modded frag, smoke, flashbang, incendiary and utility
throwables use their own projectile behaviour when somebody opens the body's inventory.

This is deliberately OFF by default because it changes a familiar inventory interaction into a
lethal risk. Full guide: https://github.com/AdamWaldie/WaldosMissionPack/wiki/ACE-Corpse-Traps
*/
Waldo_CorpseTraps_Enable = false;
if (Waldo_CorpseTraps_Enable) then {
    [] call Waldo_fnc_CorpseTrapInit;
};

/*
After-Action WIA listener (ACE)

ACE raises "ace_unconscious" locally on the machine owning the unit, so it cannot be caught by the
server-only EntityKilled handler in Waldo_fnc_AARTrack. This all-machines listener forwards each
unit's first unconsciousness to the server (Waldo_fnc_AARWound) so the ENDEX debrief can show WIA
per side. Counts each unit once. Silently absent if ACE medical is not loaded.
*/
if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then {
    ["ace_unconscious", {
        params ["_unit", "_state"];
        if (_state && {local _unit} && {!(_unit getVariable ["Waldo_AAR_Wounded", false])}) then {
            _unit setVariable ["Waldo_AAR_Wounded", true];
            [[west, east, independent, civilian] find (side group _unit)] remoteExec ["Waldo_fnc_AARWound", 2];
        };
    }] call CBA_fnc_addEventHandler;
};

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

This section deals with setting up preset radio channels. Channel Naming is currently unavailable as it causes ACRE radios to be inconsistent.

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


/*
ACRE 2 Babel Setup

The script activates the Babel system in Arma 3 with Advanced Combat Radio Environment 2 (ACRE2). It sets up the languages spoken by different sides and defines the languages spoken by interpreters. 
It adds all the necessary languages to the ACRE2 Babel system, assigns them to the respective units based on the side they belong to, and creates a diary record with a list of languages spoken in the area.

Arguments:
_languages - An array of sub-arrays. Each sub-array contains a side (West, East, Independent, Civilian) and the languages they speak as strings. 
_interpreters - An array of units that are interpreters. These units can speak all languages.

Example:
[
    [
        [West, "English","French"],
        [East, "Chinese"],
        [independent, "Altian"],
        [civilian, "Altian"]
    ],
    [unit, unit2]
] call Waldo_fnc_BabelActivation;

*/
/*
[
	[
		[west, "English", "French"],
		[east, "Russian"],
		[civilian, "French"]
	]
] call Waldo_fnc_BabelActivation;
*/
/*
ACRE 2 CEOI

The Below list are named channels for you to assign names to. These names will appear in the CEOI, and assigned appropriately to a channel number from 1 to 99.
The position of each channel in the list determines which channel number it will be assigned in the CEOI. E.g. The second Entry ("PLATOON 2" in the example given) will be channel 2 in the CEOI.

This is broken down per Side as displayed.

*/

_LongRangeRadioChannels_BLUFOR = ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"];
missionNamespace setVariable ["Waldo_ACRE2Setup_LRChannels_BLUFOR", _LongRangeRadioChannels_BLUFOR];
_LongRangeRadioChannels_OPFOR = ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"];
missionNamespace setVariable ["Waldo_ACRE2Setup_LRChannels_OPFOR", _LongRangeRadioChannels_OPFOR];
_LongRangeRadioChannels_IND = ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"];
missionNamespace setVariable ["Waldo_ACRE2Setup_LRChannels_IND", _LongRangeRadioChannels_IND];
_LongRangeRadioChannels_CIV = ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"];
missionNamespace setVariable ["Waldo_ACRE2Setup_LRChannels_CIV", _LongRangeRadioChannels_CIV];


/*===========================================================================================================================*/

/*
Localised Radio Jamming (ACRE2 / TFAR)

Area-denial radio jamming for both ACRE2 and TFAR. A "jammer" is any object with a radius: radios
inside its field (ACRE2) or players standing in it (TFAR) lose comms, with a linear falloff at the
edge. You can jam everyone or only chosen sides, and (ACRE2 only) restrict it to frequency bands.

Set up jammers however suits you:
- From an object's init field in Eden:      [this] call Waldo_fnc_Jammer;                  // 300 m, jams all
                                            [this, 500, "EAST"] call Waldo_fnc_Jammer;      // 500 m, OPFOR only
- From a trigger / script:                  [myTower, 800, "ALL", [[30,88]]] call Waldo_fnc_Jammer;
- Live from Zeus ("Waldos Mission Modules"): Radio Jammer - Place / Toggle Nearest / Remove Nearest.

Toggle or remove later with [ref, active] call Waldo_fnc_JammerToggle; and [ref] call Waldo_fnc_JammerRemove;
(ref = the jammer object or the id returned by Waldo_fnc_Jammer).

ACRE2 note: your ACRE2 signal model must be "LOS Multipath" (the default) or "Arcade" for jamming to
apply. Full guide: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Radio-Jamming

The feature installs its radio engines only while enabled; with no jammers placed it has no effect.
Set Waldo_Jamming_Enable to false to disable it entirely; Waldo_Jamming_Notify controls the on-screen
jamming meter players see when they enter a field.

Model options (tune the realism/gameplay to taste):
- Waldo_Jamming_LOS            true  = terrain/hills block the jamming field (line of sight)
- Waldo_Jamming_BurnThrough    true  = higher-power radios (e.g. PRC-117F) resist jamming, shrinking
                                       the effective field; Waldo_Jamming_BurnThroughRef is the mW
                                       reference power (a radio at this power is fully affected)
- Waldo_Jamming_Curve          "LINEAR" or "INVSQ" edge falloff
- Waldo_Jamming_Destructible   true  = destroying a jammer's object removes it (EW objectives)
- Waldo_Jamming_GmOverlay      true  = curators see a floating marker over each jammer
- Waldo_Jamming_ScanRange      detection range (m) of the handheld RDF "Scan for Radio Jammers" action
*/
Waldo_Jamming_Enable = true;
missionNamespace setVariable ["Waldo_Jamming_Notify", true, true];
missionNamespace setVariable ["Waldo_Jamming_LOS", true, true];
missionNamespace setVariable ["Waldo_Jamming_BurnThrough", true, true];
missionNamespace setVariable ["Waldo_Jamming_BurnThroughRef", 500, true];
missionNamespace setVariable ["Waldo_Jamming_Curve", "LINEAR", true];
missionNamespace setVariable ["Waldo_Jamming_Destructible", true, true];
missionNamespace setVariable ["Waldo_Jamming_GmOverlay", true, true];
missionNamespace setVariable ["Waldo_Jamming_ScanRange", 3000, true];
if (Waldo_Jamming_Enable) then {
    missionNamespace setVariable ["Waldo_Jamming_Enable", true, true];
    [] call Waldo_fnc_JammingInit;
};


/*===========================================================================================================================*/

/*
Vehicle function eventhandler

This adds vehicle functions to affected vehicles:
- Get out on specfic side. Only affects RHS gear so far.
- Auto added medical/logistics status to vehicles.  Only affects RHS gear so far.
- HALO / Static line [WIP] Only affects RHS gear so far.

*/
call Waldo_fnc_InitVehicles;

/*

Briefing documents

*/
call Waldo_fnc_AddDocs;

/*

Sets team colour based on contents of role description.
Colour selections are RED,BLUE,GREEN,YELLOW.
Name Selections are ALPHA,BRAVO,CHARLIE,DELTA - which maps to colours as in colour selections.
Role selections are SQUAD Leader (Yellow), MEDIC (Green).

Currently based on the first word in the role description.

So Squad Leader will trigger assignment as Yellow but Viking Squad Leader will not- will likely refine this later.

*/
call Waldo_fnc_SetTeamColour;

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

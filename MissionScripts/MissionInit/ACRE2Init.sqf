/*
Purpose: ACRE2 Initilisation Script (CO-OP)
Called From: Init.sqf
Scope: All players within mission.
Execution time: Mission start (+/- 1 minute)
Author: Adam Waldie
License: Distributable and editable with proper attribution.

How to call:
From init.sqf

This is done for you in mission packs.

The only change nessicary is the GROUP NAMES and CHANNELS PER RADIO in missionParameters.sqf

*/


//Check for, and exit if not present: ACRE2
if !(isClass(configFile >> "CfgPatches" >> "acre_main")) exitWith {};

/* -------------------------------------------------------------------------------

Whole Side Radio Channel Names / wavelength assignment - DISABLED DUE TO ACRE2 INSTABILITY

----------------------------------------------------------------------------------
Below, we simply name all the channels for each radio, to matching names. This will make the radios
in game (and in the popup hint) show the NAME of the channel they are speaking on.
Next, we rename the first 6 channels on each radios preset. The field names are different for each
radio type because they are dependent of the radio's programming and configuration. This was done
in ACRE2 because the actual field names match the technical specifications of how these radios
internally handle their data.

Although the names are different, they serve the same purpose. "name", "description" and "label" are
the 3 different ways the 148, 152 and 117 reference their internal channel naming schemes.

["ACRE_PRC152", "defaultMissionRadios", 1, "description", "PLATOON"] call acre_api_fnc_setPresetChannelField;
["RADIO", "RADIO_TEMPLATE_GROUP", 1, "description", "CHANNEL NAME"] call acre_api_fnc_setPresetChannelField;

ONLY CHANGE THE CHANNEL NAME!

*/
/*
//Establish radio presets from default
["ACRE_PRC152", "default", "defaultMissionRadios"] call acre_api_fnc_copyPreset;
["ACRE_PRC148", "default", "defaultMissionRadios"] call acre_api_fnc_copyPreset;
["ACRE_PRC117F", "default", "defaultMissionRadios"] call acre_api_fnc_copyPreset;

//Set 152 radio channel names & number associations.
["ACRE_PRC152", "defaultMissionRadios", 1, "description", "PLATOON"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC152", "defaultMissionRadios", 2, "description", "PLATOON 2"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC152", "defaultMissionRadios", 3, "description", "AIR 2 GROUND"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC152", "defaultMissionRadios", 4, "description", "AIR 2 AIR"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC152", "defaultMissionRadios", 5, "description", "CONVOY"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC152", "defaultMissionRadios", 6, "description", "COMPANY"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC152", "defaultMissionRadios", 7, "description", "CAS 1"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC152", "defaultMissionRadios", 8, "description", "CAS 2"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC152", "defaultMissionRadios", 9, "description", "CFF 1"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC152", "defaultMissionRadios", 10, "description", "CFF 2"] call acre_api_fnc_setPresetChannelField;

//Set 148 radio channel names & number associations.
["ACRE_PRC148", "defaultMissionRadios", 1, "label", "PLATOON"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC148", "defaultMissionRadios", 2, "label", "PLATOON 2"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC148", "defaultMissionRadios", 3, "label", "AIR 2 GROUND"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC148", "defaultMissionRadios", 4, "label", "AIR 2 AIR"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC148", "defaultMissionRadios", 5, "label", "CONVOY"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC148", "defaultMissionRadios", 6, "label", "COMPANY"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC148", "defaultMissionRadios", 7, "label", "CAS 1"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC148", "defaultMissionRadios", 8, "label", "CAS 2"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC148", "defaultMissionRadios", 9, "label", "CFF 1"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC148", "defaultMissionRadios", 10, "label", "CFF 2"] call acre_api_fnc_setPresetChannelField;

//Set 117F radio channel names & number associations.
["ACRE_PRC117F", "defaultMissionRadios", 1, "name", "PLATOON"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC117F", "defaultMissionRadios", 2, "name", "PLATOON 2"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC117F", "defaultMissionRadios", 3, "name", "AIR 2 GROUND"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC117F", "defaultMissionRadios", 4, "name", "AIR 2 AIR"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC117F", "defaultMissionRadios", 5, "name", "CONVOY"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC117F", "defaultMissionRadios", 6, "name", "COMPANY"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC117F", "defaultMissionRadios", 7, "name", "CAS 1"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC117F", "defaultMissionRadios", 8, "name", "CAS 2"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC117F", "defaultMissionRadios", 9, "name", "CFF 1"] call acre_api_fnc_setPresetChannelField;
["ACRE_PRC117F", "defaultMissionRadios", 10, "name", "CFF 2"] call acre_api_fnc_setPresetChannelField;

//Apply presets above to specified radio types - regardless of side.
["ACRE_PRC152", "defaultMissionRadios"] call acre_api_fnc_setPreset;
["ACRE_PRC148", "defaultMissionRadios"] call acre_api_fnc_setPreset;
["ACRE_PRC117F", "defaultMissionRadios"] call acre_api_fnc_setPreset;
*/

/* -------------------------------------------------------------------------------

Radio Channel Presetting

----------------------------------------------------------------------------------

The following lines is a selection statement, based on the parameters set in missionParameters.sqf DO NOT EDIT THIS DIRECTLY.
It is based on the groupID you have given to each player group. Alpha 1-1/ Bravo 3-1 as examples.

THIS IS ALL SET VIA THE missionPresets.sqf FILE IN THE ROOT DIRECTORY OF THIS MISSION!

As for what its actually doing in each case:
- checks to see if a radio of the type exists, then sets the radio channel designated, followed by setting the side in which the radio will speak to the user from. These can be changed ingame by the player.

{if ([_x, "ACRE_PRC343"] call acre_api_fnc_isKindOf) then {[_x,5] call acre_api_fnc_setRadioChannel; [_x,"LEFT"] call acre_api_fnc_setRadioSpatial}} forEach _radioList;
{if ([_x, "RADIO_BASE_CLASS"] call acre_api_fnc_isKindOf) then {[_x,CHANNEL_NUMBER] call acre_api_fnc_setRadioChannel; [_x,"EAR_TO_PLAY_THROUGH"] call acre_api_fnc_setRadioSpatial}} forEach _radioList;

*/
//Get Arguments for call
private _ACRESetups = _this select 0;
/*
//Inline CBA System  - One day, I will get this variant to work properly.
[{
   call acre_api_fnc_isInitialized;
},{
{
	{
		private ["_group","_radioList","_unitName","_r343","_r152","_r148","_r117f"];
		systemchat format["Values Are: %1",str _x];
		_group = groupId(group player); // Get Group Name
		_radioList = [] call acre_api_fnc_getCurrentRadioList;//Get Current list of radios on that player
		//Breakdown incoming ACRE parameters into manageable segments
		//Select incoming variable, get current iteration, and then select the Name, and radio channel as formatted respectively.
		_unitName = _x select 0;
		_r343 = _x select 1;
		//Verify that each "number" is not a string, and if so, numberfy it
		if (typeName _r343 isEqualTo "STRING") then {_r343 = parseNumber _r343;};
		_r152 = _x select 2;
		if (typeName _r152 isEqualTo "STRING") then {_r152 = parseNumber _r152;};
		_r148 = _x select 3;
		if (typeName _r148 isEqualTo "STRING") then {_r148 = parseNumber _r148;};
		_r117f = _x select 4;
		if (typeName _r117f isEqualTo "STRING") then {_r117f = parseNumber _r117f;};
		//Ensure Group == callsign, when true, set radios accordingly.
		if (_group isEqualTo _unitName) then {
			{if ([_x, "ACRE_PRC343"] call acre_api_fnc_isKindOf) then {[_x,_r343] call acre_api_fnc_setRadioChannel; [_x,"LEFT"] call acre_api_fnc_setRadioSpatial}} forEach _radioList;
			{if ([_x, "ACRE_PRC152"] call acre_api_fnc_isKindOf) then {[_x,_r152] call acre_api_fnc_setRadioChannel; [_x,"RIGHT"] call acre_api_fnc_setRadioSpatial}} forEach _radioList;
			{if ([_x, "ACRE_PRC148"] call acre_api_fnc_isKindOf) then {[_x,_r148] call acre_api_fnc_setRadioChannel; [_x,"RIGHT"] call acre_api_fnc_setRadioSpatial}} forEach _radioList;
			{if ([_x, "ACRE_PRC117F"] call acre_api_fnc_isKindOf) then {[_x,_r117f] call acre_api_fnc_setRadioChannel; [_x,"CENTER"] call acre_api_fnc_setRadioSpatial}} forEach _radioList;
			systemchat format ["%1 has been found equal to %2",_group,_unitName];
		} else {
			systemchat format ["%1 is not equal to %2",_group,_unitName];
		};
	} forEach _args;
	_InitRespawnHandle = execvm "MissionScripts\saveRespawnLoadout.sqf";
} forEach allPlayers;}, [_ACRESetups]] call CBA_fnc_waitUntilAndExecute;
//Wait for ACRE Base Init to finish
//Announce Completed
["ACRE2 CHANNEL PRESETS COMPLETE"] remoteExec ["systemchat", 0, false];*/

//Outline System

waitUntil {[] call acre_api_fnc_isInitialized};
{
	{
		private ["_group","_radioList","_unitName","_r343","_r152","_r148","_r117f"];
		_group = groupId(group player); // Get Group Name
		_radioList = [] call acre_api_fnc_getCurrentRadioList;//Get Current list of radios on that player
		//Breakdown incoming ACRE parameters into manageable segments
		//Select incoming variable, get current iteration, and then select the Name, and radio channel as formatted respectively.
		_unitName = _x select 0;
		_r343 = _x select 1;
		//Verify that each "number" is not a string, and if so, numberfy it
		if (typeName _r343 isEqualTo "STRING") then {_r343 = parseNumber _r343;};
		_r152 = _x select 2;
		if (typeName _r152 isEqualTo "STRING") then {_r152 = parseNumber _r152;};
		_r148 = _x select 3;
		if (typeName _r148 isEqualTo "STRING") then {_r148 = parseNumber _r148;};
		_r117f = _x select 4;
		if (typeName _r117f isEqualTo "STRING") then {_r117f = parseNumber _r117f;};
		//Ensure Group == callsign, when true, set radios accordingly.
		if (_group isEqualTo _unitName) then {
			{if ([_x, "ACRE_PRC343"] call acre_api_fnc_isKindOf) then {[_x,_r343] call acre_api_fnc_setRadioChannel; [_x,"LEFT"] call acre_api_fnc_setRadioSpatial}} forEach _radioList;
			{if ([_x, "ACRE_PRC152"] call acre_api_fnc_isKindOf) then {[_x,_r152] call acre_api_fnc_setRadioChannel; [_x,"RIGHT"] call acre_api_fnc_setRadioSpatial}} forEach _radioList;
			{if ([_x, "ACRE_PRC148"] call acre_api_fnc_isKindOf) then {[_x,_r148] call acre_api_fnc_setRadioChannel; [_x,"RIGHT"] call acre_api_fnc_setRadioSpatial}} forEach _radioList;
			{if ([_x, "ACRE_PRC117F"] call acre_api_fnc_isKindOf) then {[_x,_r117f] call acre_api_fnc_setRadioChannel; [_x,"CENTER"] call acre_api_fnc_setRadioSpatial}} forEach _radioList;
			//systemchat format ["%1 has been found equal to %2",_group,_unitName];
		}; /*else {
			systemchat format ["%1 is not equal to %2",_group,_unitName];
		};*/
	} forEach _ACRESetups;
	[] call Waldo_fnc_SaveLoadout;
} forEach allPlayers;
//Announce Completed
systemchat "ACRE2 CHANNEL PRESETS COMPLETE";

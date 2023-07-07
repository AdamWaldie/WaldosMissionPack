/*
Author: Waldo
This function sets up radios for player and server, must be called via Init.sqf root (or helper function from there)

Arguments:
_RadioAssignments = Squad Radio Assignments[2D Array]

Returns:
N/A

Example:
[] call Waldo_fnc_ACRE2Init;

*/
params ["_RadioAssignments"];

if !(isClass(configFile >> "CfgPatches" >> "acre_main")) exitWith {systemChat "ACRE2 Mod Not Enabled";};

/*
// Gets a preset and a base frequency to set per side
if (missionNamespace getVariable ["Waldo_ACRE2Setup_LRChannels_CrossTalk", false]) then {
    FREQUENCY = [10.242, 10.242, 10.242, 10.242]; // same freq = same channels = all sides hear one another on radio
} else {
    FREQUENCY = [10.242, 10.442, 10.642, 10.842]; // different freq means different radio channels = all sides DO NOT hear one another
};
PRESETS = ["default","default2","default3","default4"]; // 4 defaults used per side to allow for multiple channel names/freqs if need be

{
    {
        // Handle LR channel name list from user definition, or failing that preset
        private _lrChannels = (missionNamespace getVariable [_x, ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"]]);

        //Get index of current side to use in selecting side preset and fequiency
        private _CurrentSideIndex = _forEachIndex;

        // Set LR radio labels and frequency
        {
            private _radio = _x;
            private _sidePreset = (PRESETS select _CurrentSideIndex);
            private _sideFrequency = (FREQUENCY select _CurrentSideIndex);
            {
                [_radio, _sidePreset, _forEachIndex + 1, "label", _x] call acre_api_fnc_setPresetChannelField;
                [_radio, _sidePreset, _forEachIndex + 1, "frequencyTX", (_forEachIndex + _sideFrequency)] call acre_api_fnc_setPresetChannelField;
                [_radio, _sidePreset, _forEachIndex + 1, "frequencyRX", (_forEachIndex + _sideFrequency)] call acre_api_fnc_setPresetChannelField;
            } forEach _lrChannels;
        } forEach ["ACRE_PRC152", "ACRE_PRC148", "ACRE_PRC117F"];

    } forEach ["Waldo_ACRE2Setup_LRChannels_BLUFOR","Waldo_ACRE2Setup_LRChannels_OPFOR","Waldo_ACRE2Setup_LRChannels_IND","Waldo_ACRE2Setup_LRChannels_CIV"];
} foreach allPlayers; // Super performance intensive piece of code, on which the entirety of this script is based. Without it, radios just dont work because ACRE Naming channels causes them to break - even with a copied preset


_radioSide = (PRESETS select 0);

// Set radio Preset per side
switch (side player) do
{
	case west: {_radioSide = (PRESETS select 0);}; // blufor
	case east: {_radioSide = (PRESETS select 1);}; // opfor
    case independent: {_radioSide = (PRESETS select 2);}; //indfor
	default {_radioSide = (PRESETS select 3);}; //civpop
};

{
    [_X, _radioSide] call acre_api_fnc_setPreset;
} forEach ["ACRE_PRC152", "ACRE_PRC148", "ACRE_PRC117F"];

*/
//Callsigns
private _SquadCallsigns = [];

{
    _stringPart =  _x select 0;
    _SquadCallsigns append [_stringPart];
} forEach _RadioAssignments;

[_SquadCallsigns] call Waldo_fnc_SquadLevelRadios; // Squad Level Radio Channels located

systemchat "ACRE2 PRE-INIT COMPLETE";

waitUntil {[] call acre_api_fnc_isInitialized && missionNamespace getVariable ["Waldo_ACRE2Setup_CallsignChannelAssignments_flag",false]};

// Get group and players current radiolist
_group = groupId(group player); // Get Group Name
_radioList = [] call acre_api_fnc_getCurrentRadioList;//Get Current list of radios on that player

/*
_RadioAssignments = [
    ["Viking-1-1",[1,5]],
	["Viking 5",[2,2]],
	["Viking 3.2",[3,2]],
	["Banshee",[4,1]]
];*/

// GET SR Radio CHannels to assign the AN_PRC343 Radio channel for that callsign
_SRChannelAssignments = missionNamespace getVariable ["Waldo_ACRE2Setup_CallsignChannelAssignments","FAIL"];

/*

================================================ AN/PRC-343 Assignemnt ================================================

*/

_rchannel343 = 256; //default channel as 16*16 as noticable IOF

{
    if ((toUpper (_x select 0)) == (toUpper _group) ) then {_rchannel343 = _x select 1};
} foreach _SRChannelAssignments;

{
    if ((toUpper (_x select 0)) == toUpper(_group)) then {
        _rchannel343 = _x select 1;
    };
} forEach _SRChannelAssignments;

if (_rchannel343 == 256) then {systemchat format ["Group: %1  SR channel parsing has failed, defaulted to B: 16 C: 16 ",_group];}; // notification of missing/incorrect variables

{if ([_x, "ACRE_PRC343"] call acre_api_fnc_isKindOf) then {
        [_x,_rchannel343] call acre_api_fnc_setRadioChannel; [_x,"LEFT"] call acre_api_fnc_setRadioSpatial; // Set channl and set radio on left ear by default
        _radioList deleteAt _forEachIndex;// remove ANPRC343 from radio list to account for th epotential of index out of range in LR assignment
    };
} forEach _radioList;



/*

================================================ AN/PRC-152/148/117F Assignment ================================================


*/


//Verify that each "number" is not a string, and if so, numberfy it for that it does not create errors. End users may get it wrong.
{
    _channels = _x select 1;
    {
        if (typeName _x isEqualTo "STRING") then {_x = parseNumber _x;};
    } foreach _channels;
} foreach _RadioAssignments;

_LRChannelAssignments = [99,99,99]; 

//Get Callsigns LRRadioAssignment array section
{
    if ((toUpper (_x select 0)) == (toUpper _group) ) then {_LRChannelAssignments = _x select 1};
} foreach _RadioAssignments;

{
    if ((toUpper (_x select 0)) == (toUpper _group) ) then {
        _LRChannelAssignments = _x select 1;
    };
} forEach _RadioAssignments;

if ((_LRChannelAssignments select 1 == 99) && (_LRChannelAssignments select 1 == 99) && (_LRChannelAssignments select 1 == 99)) then {systemchat format ["Group: %1 either has missing channels or parsing has failed, defaulted to C: 99 ",_group];}; // notification of missing/incorrect variables


// Assign channels based on currently existing contents of array __LRChannelAssignments. Pop when assigned to prevent reproduction, also means no limit due to radios in inventory/channels asssigned changing
{
    if (count _LRChannelAssignments >= 1) then {
        if ([_x, "ACRE_PRC152"] call acre_api_fnc_isKindOf) then {[_x,(_LRChannelAssignments select 0)] call acre_api_fnc_setRadioChannel; [_x,"RIGHT"] call acre_api_fnc_setRadioSpatial};
        if ([_x, "ACRE_PRC148"] call acre_api_fnc_isKindOf) then {[_x,(_LRChannelAssignments select 0)] call acre_api_fnc_setRadioChannel; [_x,"RIGHT"] call acre_api_fnc_setRadioSpatial};
        if ([_x, "ACRE_PRC117F"] call acre_api_fnc_isKindOf) then {[_x,(_LRChannelAssignments select 0)] call acre_api_fnc_setRadioChannel; [_x,"CENTER"] call acre_api_fnc_setRadioSpatial};
        _LRChannelAssignments deleteAt 0;
    } else {
        systemchat format["Callsign: %1 was unable to be assigned one or more radio channels due to an excess of LR radios",_group];
    };
} foreach _radioList;

//Save channels with loadout
[] call Waldo_fnc_SaveLoadout;

systemchat "ACRE2 RADIO PRESET COMPLETE";


/*
ACRE 2 RADIO SETUP PARAMETERS

This section deals with setting up preset radio channels and marking out the pre-set channels to set player squads to.

Please referance the wiki to set this up properly.

LongRangeRadioChannels_BLUFOR is the list of channel names to be displayed on the radio interface for the WEST or BLUFOR side. Opfor, IND and CIV are self explanatory.
Edit these to your hearts content, each of them can be up to 99 entries.

Do not remove sides if they are not in use.

*/
/*

DUE TO ACRE2 Limitations, channel naming does not work

//Starting from the far left of the array the channel will start from 1 - I.e. in the below example PLATOON 1 is Channel 1, PLATOON 3 IS Channel 3
_LongRangeRadioChannels_BLUFOR = ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"];
missionNamespace setVariable ["Waldo_ACRE2Setup_LRChannels_BLUFOR", _LongRangeRadioChannels_BLUFOR];
_LongRangeRadioChannels_OPFOR = ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"];
missionNamespace setVariable ["Waldo_ACRE2Setup_LRChannels_OPFOR", _LongRangeRadioChannels_OPFOR];
_LongRangeRadioChannels_IND = ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"];
missionNamespace setVariable ["Waldo_ACRE2Setup_LRChannels_IND", _LongRangeRadioChannels_IND];
_LongRangeRadioChannels_CIV = ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"];
missionNamespace setVariable ["Waldo_ACRE2Setup_LRChannels_CIV", _LongRangeRadioChannels_CIV];

// The Below variable determines whether all sides share the same base frequency and therefore can speak to each other on the same frequencies, or not. True = All can speak to each other. False = seperate nets.
missionNamespace setVariable ["Waldo_ACRE2Setup_LRChannels_CrossTalk", false];*/

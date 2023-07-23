/*//    INFO TEXT    //// ==========================================================================================

Can be called on mission start via missionParameters.sqf with setup.

Or via the the use of the following command, edited with string for the desired segmentation
Introduction Text - Cool Introduction stuff like location, date, time and mission name and locale
There are two parameters. The Name Of The Mission & The locale of the mission.

This is the most basic iteration, it automatically grabs the mission title & location based on description.ext for title, and worldName for location.
[] spawn Waldo_fnc_ENDEX;

There are date formats that can be used, short format and long format. This is a boolean value and defaults to false (short date) if left blank.
Short Date Format is "01/11/2010"
Long Date Format is "1st November 2010"
The date can be overwritten with a direct string input on line 91 - useful for fictional dates in Star Wars and Warhammer 40k.

You can also customise the information text directly, by providing additional parameters. The first additional entry will be the title, while the second will be the location. An example use is in the example mission.
An animation can also be specified in the third argument by inputting a String. Options are;

	"NONE" 		- No animation
	"WALK" 		- Slow walk forward
	"SIT" 		- Stand from sitting on floor
	"WAKE		- Wake up and stand.
	"WAKESLOW" 	- Much longer version of "WAKE". Character stands more cautiously.
	"COFFIN"	- Meme input. Rise from the ground like Nosferatu.

["CUSTOM TITLE", "CUSTOM LOCATION",LONG OR SHORT DATE,"ANIMATION SELECTION"] spawn Waldo_fnc_InfoText;

*/

params[["_title",""],["_locale",""],["_longDate",false],["_anim","NONE"]];

waitUntil {!isNull findDisplay 46};
//Grab Mission Name & Terrain Name automatically
//If provided with a string in the correct parameter slot, accepts that inplace of the automatic generation
_missionTitle = getText (missionConfigFile >> "onLoadName");; 
if (_title != "") then {
	_missionTitle = _title;
};
_localeName = worldName;
if (_locale != "") then {
	_localeName = _locale;
};
_animate = "NONE";
if (_anim != "NONE") then {
	_animate = _anim;
};

//No runnin' off..
disableUserInput true;

// ----- DATE SETTING -----
_date = if (_longDate) then {


	_dateOW = [date select 0,date select 1,date select 2,0,0];
	_yearBefore = ((_dateOW select 0)-1) max 0;
	_qttLeapYears = floor (_yearBefore/4);
	_qttNormalYears = _yearBefore-_qttLeapYears;
	_daysOW = _qttNormalYears+_qttLeapYears*(366/365);
	_daysOW = _daysOW+dateToNumber _dateOW;
	_dayOfWeekNo = (round (_daysOW/(1/365))) mod 7;

	_dayOfWeek = switch (_dayOfWeekNo) do{
		case 0: {"Sunday"};
		case 1: {"Monday"};
		case 2: {"Tuesday"};
		case 3: {"Wednesday"};
		case 4: {"Thursday"};
		case 5: {"Friday"};
		case 6: {"Saturday"};
		default {""};
	};

	_dayExt = switch (date select 2) do {
		case 1: {"st"};
		case 2: {"nd"};
		case 3: {"rd"};
		case 21: {"st"};
		case 22: {"nd"};
		case 23: {"rd"};
		case 31: {"st"};
		default {"th"};
	};

	_day = str (date select 2) + _dayExt;

	_month = switch (date select 1) do {
		case 1: {"January"};
		case 2: {"February"};
		case 3: {"March"};
		case 4: {"April"};
		case 5: {"May"};
		case 6: {"June"};
		case 7: {"July"};
		case 8: {"August"};
		case 9: {"September"};
		case 10: {"October"};
		case 11: {"November"};
		case 12: {"December"};
		default {date select 2};
	};

	_dayOfWeek + ' ' + _day + ' ' + _month + ' ' + str (date select 0);

} else {
	str (date select 2) + '/' + str (date select 1) + '/' + str (date select 0);
};

// Use the below parameter to overwrite the date - useful for fictional dates in Star Wars or Warhammer 40k. Put your date inbetween the 2 quotation marks.
//_date = "";

// ----- TIME SETTING -----
_timeConfig = [dayTime, "ARRAY"] call BIS_fnc_timeToString; 
_time = (_timeConfig select 0) + (_timeConfig select 1) + ' hrs';

// ----- LOCATION SETTING -----
_missionTime = str (time/60);
_localePos = 'Grid ' + mapGridPosition player + ', ' + _localeName; 
_groupInfo = rank player + ' ' + name player + ', ' + groupID (group player);

// ---- TEXT FORMATTING -----
_textColour = switch (side player) do
{
	case west: {"'#0055aa'"};
	case east: {"'#770000'"};
	case resistance: {"'#008e00'"};
	case civilian: {"'#65007e'"};
	default {"'#ed9d18'"};
};

waitUntil { uiSleep 1; (!isNull player && time > 0) };

// ----- COMPLILE INFO AND DISPLAY TO PLAYER -----
// Throw up a fake loading screen to buffer over actual loading screen.

["fauxLoad", ""] call BIS_fnc_startLoadingScreen;
uiSleep 9;
["wakeUpID", false, 5] call BIS_fnc_blackOut;	// Fade screen out to black for intro sequence.
uiSleep 1;
"fauxLoad" call BIS_fnc_endLoadingScreen; // End fake loading screen and begin displaying text.

uiSleep 5;

[
	[
		[_time, "<t align = 'center' shadow = '1' size = '1.0'>%1</t><br/>"],
		[_date, "<t align = 'center' shadow = '1' size = '0.7' font='PuristaBold'>%1</t><br/>", 10]
	]
] spawn BIS_fnc_typeText;
uiSleep 6;

_text1 = str composeText ["<t align = 'center' shadow = '1' size = '1.0' font='PuristaBold' color=", _textColour, ">%1</t><br/>"];  
_text2 = "<t align = 'center' shadow = '1' size = '0.8' color='#808080'>%1</t><br/>";  
_text3 = "<t align = 'center' shadow = '1' size = '0.7'>%1</t>";  

[  
    [  
        [_missionTitle, _text1],  
        [_localePos, _text2],  
        [_groupInfo, _text3, 5]  
    ]  
] spawn BIS_fnc_typeText;

uiSleep 3;

// ----- ANIMATION SETTING -----
_unit = player;
// Determine animation to use from given Params
_usedAnimation = switch (_animate) do {
	case "NONE": {};
	
	case "WALK": {
		[_unit] spawn {
			params ["_unit"];
			[_unit, "Acts_welcomeOnHUB02_PlayerWalk_1"] remoteExec ["switchMove", 0];
			sleep 8.333;
			[_unit, "AmovPercMstpSlowWrflDnon"] remoteExec ["switchMove", 0];
		};
	};

	case "SIT": {
		[_unit] spawn {
			params ["_unit"];
			[_unit, "AmovPsitMstpSrasWrflDnon_WeaponCheck1"] remoteExec ["switchMove", 0];
			sleep 8.666;
			[_unit, "AmovPsitMstpSrasWrflDnon_AmovPercMstpSlowWrflDnon"] remoteExec ["switchMove", 0];
		};
	};

	case "WAKE" : {
		[_unit] spawn {
			params ["_unit"];
			[_unit, "Acts_Waking_Up_Player"] remoteExec ["switchMove", 0];
		};
	};

	case "WAKESLOW" : {
		[_unit] spawn {
			params ["_unit"];
			[_unit, "Acts_UnconsciousStandUp_part1"] remoteExec ["switchMove", 0];
		};
	};

	case "COFFIN" : {
		[_unit] spawn {
			params ["_unit"];
			[_unit, "Acts_Undead_Coffin"] remoteExec ["switchMove", 0];
			sleep 6.666;
			[_unit, "AmovPercMstpSlowWrflDnon"] remoteExec ["switchMove", 0];
		};
	};

	default {};
};

["wakeUpID", true, 3] call BIS_fnc_blackIn;
disableUserInput false;

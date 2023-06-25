/*//    INFO TEXT    //// ==========================================================================================

Can be called on mission start via missionParameters.sqf with setup.

Or via the the use of the following command, edited with string for the desired segmentation
Introduction Text - Cool Introduction stuff like location, date, time and mission name and locale
There are two parameters. The Name Of The Mission & The locale of the mission.

This is the most basic iteration, it automatically grabs the mission title & location based on description.ext for title, and worldName for location.
[] spawn Waldo_fnc_ENDEX;

You can also customise the information text directly, by providing additional parameters. The first additional entry will be the title, while the second will be the location. An example use is in the example mission.
An animation can also be specified in the third argument by inputting a String. Options are;

	"NONE" 		- No animation
	"WALK" 		- Slow walk forward
	"SIT" 		- Stand from sitting on floor
	"WAKE		- Wake up and stand.
	"WAKESLOW" 	- Much longer version of "WAKE". Character stands more cautiously.
	"COFFIN"	- Meme input. Rise from the ground like Nosferatu.

["CUSTOM TITLE", "CUSTOM LOCATION","ANIMATION SELECTION"] spawn Waldo_fnc_InfoText;

*/


params[["_title",""],["_locale",""],["_anim","NONE"]];

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


_timeConfig = [dayTime, "ARRAY"] call BIS_fnc_timeToString; 
_time = (_timeConfig select 0) + (_timeConfig select 1) + ' hrs';

_date =  str (date select 2) + '/' + str (date select 1) + '/' + str (date select 0);
_missionTime = str (time/60);
_localePos = 'Grid ' + mapGridPosition player + ', ' + _localeName; 
_groupInfo = rank player + ' ' + name player + ', ' + groupID (group player);

_textColour = switch (side player) do
{
	case west: {"'#0055aa'"};
	case east: {"'#770000'"};
	case resistance: {"'#008e00'"};
	case civilian: {"'#65007e'"};
	default {"'#ed9d18'"};
};

waitUntil { uiSleep 1; (!isNull player && time > 0) };

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

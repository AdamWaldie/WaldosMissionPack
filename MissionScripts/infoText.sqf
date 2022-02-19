/*//    INFO TEXT    //// ==========================================================================================

Can be called on mission start via missionParameters.sqf with setup.

Or via the the use of the following command, edited with string for the desired segmentation
Introduction Text - Cool Introduction stuff like location, date, time and mission name and locale
There are two parameters. The Name Of The Mission & The locale of the mission You can change these below

This is the most basic iteration, it automatically grabs the mission title & location based on description.ext for title, and worldName for location.
[] call Waldo_fnc_InfoText;

You can also customise the information text directly, by providing additional parameters. The first additional entry will be the title, while the second will be the location. An example use is in the example mission.
["CUSTOM TITLE", "CUSTOM LOCATION"] call Waldo_fnc_InfoText;

*/


params[["_title","DEFAULT"],["_locale","DEFAULT"]];

waitUntil {!isNull findDisplay 46};
_missionTitle = getText (missionConfigFile >> "onLoadName");; 
if (_title != "DEFAULT") then {
	_missionTitle = _title;
};
_localeName = worldName;
if (_locale != "DEFAULT") then {
	_localeName = _locale;
};
_timeConfig = [dayTime, "ARRAY"] call BIS_fnc_timeToString; 
_time = (_timeConfig select 0) + (_timeConfig select 1) + ' hrs';

_date =  str (date select 2) + '/' + str (date select 1) + '/' + str (date select 0); //Returns ingame Date.
_missionTime = str (time/60);
_localePos = 'Grid ' + mapGridPosition player + ', ' + _localeName; // Combo to give Eg - "Grid 061223, Kavala, Altis".
_groupInfo = rank player + ' ' + name player + ', ' + groupID (group player);

_textColour = switch (side player) do
{
	case west: {"'#0055aa'"};
	case east: {"'#770000'"};
	case resistance: {"'#008e00'"};
	case civilian: {"'#65007e'"};
	default {"'#ed9d18'"};
};
waitUntil { sleep 1; (!isNull player && time > 0) };
sleep 1;
[
	[
		[_time, "<t align = 'center' shadow = '1' size = '1.0'>%1</t><br/>"],
		[_date, "<t align = 'center' shadow = '1' size = '0.7' font='PuristaBold'>%1</t><br/>", 10]
	]
] spawn BIS_fnc_typeText;
sleep 6;

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
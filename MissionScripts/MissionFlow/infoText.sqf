/*//    INFO TEXT    //// ==========================================================================================

This feature is designed to create a formatted and easily customised title text sequence to run on mission start, displaying the following information:
1. Mission Title (Pulled from the description.ext or manually specified by the mission maker)
2. Mission Time/Date (Automatic)
3. Name of the map the mission is on (Customisable directly by the mission maker)
4. Grid reference of the player at the time of the title. (Automatic)
5. Group name, Player Rank and Player Name. (Automatic)

By default, an uncustomised version of this will run via the init.sqf.

## Setup And Examples

Two parameters can be manually specified by the mission maker - the Name Of The Mission & The locale of the mission.

The below is the most basic form, this will function adequately in most maps.

[] spawn Waldo_fnc_ENDEX;

You can also customise the information text directly by providing additional parameters. 
The first additional entry will be the title, while the second will be the location. 
You may leave one or both parameters as an empty string as seen in the Ardennes example.

["CUSTOM TITLE", "CUSTOM LOCATION"] spawn Waldo_fnc_InfoText;

This may be required when you are using a map which has a weird extension, to use an example - the Ardennes map from Northen Fronts has this extension: SWU_Ardennes_1940.

["","Montherme, Belguim"] call Waldo_fnc_InfoText;

*/


params[["_title",""],["_locale",""]];

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
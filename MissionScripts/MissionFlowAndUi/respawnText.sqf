/*//    INFO TEXT    //// ==========================================================================================

This feature is designed to create a formatted and easily customised text sequence to run on respawn, displaying the following information:
1. Rank, Group Name, Player Name
2. Time, Date
3. Grid Referance

[] spawn Waldo_fnc_RespawnText;

*/
_timeConfig = [dayTime, "ARRAY"] call BIS_fnc_timeToString; // Returns ingame time
_time = (_timeConfig select 0) + (_timeConfig select 1) + ' hrs';
_date =  str (date select 2) + '/' + str (date select 1) + '/' + str (date select 0); //Returns ingame Date. (Would ususally be in "_date")
// INFO TEXT >> Do not edit the below =============================================================================
_localePos = 'Grid ' + mapGridPosition player; // Combo to give Eg - "Grid 061223".
_groupInfo = groupID (group player);
_RnkAndName = rank player + ' ' + name player;

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
		[_time, "<t align = 'center' shadow = '1' size = '0.7'>%1</t><br/>"],
		[_date, "<t align = 'center' shadow = '1' size = '0.6' font='PuristaBold'>%1</t><br/>", 10]
	],
	-safezoneX + 0.2, ((safeZoneY + safeZoneH / 2) + 0.2)
] spawn BIS_fnc_typeText;
sleep 6;

_text1 = str composeText ["<t align = 'center' shadow = '1' size = '0.7' font='PuristaBold' color=", _textColour, ">%1</t><br/>"];  
_text2 = "<t align = 'center' shadow = '1' size = '0.6'>%1</t><br/>";  
_text3 = "<t align = 'center' shadow = '1' size = '0.6'>%1</t><br/>";  
  
[  
    [  
        [_RnkAndName, _text1],  
		 [_groupInfo, _text3],
        [_localePos, _text2, 15] 
    ],
	-safezoneX + 0.2, ((safeZoneY + safeZoneH / 2) + 0.2) 
] spawn BIS_fnc_typeText;
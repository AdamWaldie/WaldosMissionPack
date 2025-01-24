/*
Author: Waldo
This is a hollow proceedure to call third party scripts and generally keep the init looking cleaner for the packs scripts.

Arguments:
N/A

Returns:
N/A

Example:
[] execVM "MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf";

Called from the Init.sqf if in use

*/

/* 

Player Makers Script (Best utilised When ACE Markers Are Not An Option)

Parameters >>
	"players" - Will show players.
	"ais" - Will show AIs.
	"allsides" - Will show all sides not only the units on player's side.
	"all" - Enable all of the above.
	"stop" - Stop the script.

Example code - 0 = ["players"] execVM "player_markers.sqf";

*/
//0 = ["players"] execVM "MissionScripts\ThirdPartyScripts\player_markers.sqf";


/*
Werthless Headless Client call

Requires:
Virtual Headless Client Entity

Reccomended to leave call as is. Information regarding HC can be found in the associated third party script.
*/
//[true,30,false,true,30,10,true,[]] execVM "MissionScripts\ThirdPartyScripts\WerthlesHeadless.sqf";
//[true,30,false,true,30,10,true,[]] spawn Waldo_fnc_WerthlesHeadless;
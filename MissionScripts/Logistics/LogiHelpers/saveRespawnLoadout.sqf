/*
Purpose: Save respawn loadout at arsenals.
Called From: addaction
Scope: missionnamespace
Execution time: on addaction use.
Author: Adam Waldie
For: Rooster Teeth Gaming Community
License: Distributable and editable, no attribution required.

Called from MissionScripts\ACRE2Init.sqf

How to use:

Any object init:
this addAction ["<t color='#00FF00'>Save Respawn Loadout</t>", Waldo_fnc_SaveLoadout];


In scripts

[] call Waldo_fnc_SaveLoadout;


*/
[player, [missionNamespace, "Waldo_Player_Inventory"]] call BIS_fnc_saveInventory;
[] spawn {
	hint "Respawn Loadout Updated!";
	sleep 5;
	hint "";
};

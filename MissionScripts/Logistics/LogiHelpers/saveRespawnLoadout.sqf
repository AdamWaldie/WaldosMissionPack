/*
Purpose: Save respawn loadout at arsenals.
Called From: addaction
Scope: missionnamespace
Execution time: on addaction use.
Author: WaldoTheWarfighter
For: Rooster Teeth Gaming Community
License: Distributable and editable, no attribution required.

Called from multiple sources

How to use:

Any object init:
this addAction ["<t color='#00FF00'>Save Respawn Loadout</t>", Waldo_fnc_SaveLoadout];


In scripts

[] call Waldo_fnc_SaveLoadout;


*/
[player, [missionNamespace, "Waldo_Player_Inventory"], [], false] call BIS_fnc_saveInventory;
[
    "RESPAWN LOADOUT SAVED",
    "Your current equipment will be restored when you respawn.",
    "SUCCESS",
    5,
    "TOP_RIGHT",
    "RESPAWN_LOADOUT",
    "PLAYER LOADOUT",
    "REPLACE"
] call Waldo_fnc_ShowUiNotification;

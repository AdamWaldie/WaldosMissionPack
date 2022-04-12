/*
This is a joiner function called directly from initServer.sqf to setup all of the loadouts for all sides, on all playable characters to setup the starter crates, limited arsenals and supply boxes & zeus boxes.

Call:
[] call Waldo_fnc_SideBaseLoadoutSetup;

*/

// Call mission lookup script per side to grab data & set it as variable.
loadoutArray_west = ["West"] call Waldo_fnc_MissionSQMLookup; 
missionNamespace setVariable ["Logi_MissionSQMArray_West", loadoutArray_west,true];
loadoutArray_east = ["East"] call Waldo_fnc_MissionSQMLookup; 
missionNamespace setVariable ["Logi_MissionSQMArray_East", loadoutArray_east,true];
loadoutArray_ind = ["Independent"] call Waldo_fnc_MissionSQMLookup; 
missionNamespace setVariable ["Logi_MissionSQMArray_Ind", loadoutArray_ind,true];
loadoutArray_civ = ["Civilian"] call Waldo_fnc_MissionSQMLookup; 
missionNamespace setVariable ["Logi_MissionSQMArray_Civ", loadoutArray_civ,true];

//Set Value To Say That Mission Scan Is Complete
missionNamespace setVariable ["Logi_MissionScanComplete", true,true];
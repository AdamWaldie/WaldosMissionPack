/*//    INFO TEXT    //// ==========================================================================================

This is used to setup the logistics spawning system, via the "Quartermaster". The quartermaster is an object or NPC which acts as the spawner for these supply boxes & equipment.

The call for this is as below:
[QuartermasterObject,SpawningObject,"SpawningCustomAmmobox"] call Waldo_fnc_SetupQuarterMaster; this disableAI "MOVE";

where the QuartermasterObject is the object the addaction is applied to. The SpawningObject is the object from which the box is spawned & the final parameter is an optional overwrite of the
missionspace variable controlling what the ammo & medical boxes are spawned as for greater control per quartermaster.

Examples:
[this,logisticsSpawn,"Box_IDAP_Equip_F"] call Waldo_fnc_SetupQuarterMaster; this disableAI "MOVE";

[this,logisticsSpawn,"Box_NATO_Ammo_F"] call Waldo_fnc_SetupQuarterMaster; this disableAI "MOVE";

- This will instead rely on the missionnamespace defined boxes:

[this,logisticsSpawn] call Waldo_fnc_SetupQuarterMaster; this disableAI "MOVE";

These are from the exemplar mission
*/

params["_unit","_spawnObject",["_customBox",""]];
//Verify if Ace Medical is present, if so, enable ACE_Medical Box setup, else pass a vanialla support box to be filled with FirstAidKits & Medical Packs
if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then {
    _unit addAction ['Spawn Medical Box', "MissionScripts\Logistics\LogiBoxes.sqf", ["Medical",_spawnObject, _customBox, true]];
} else {
    _unit addAction ['Spawn Medical Box', "MissionScripts\Logistics\LogiBoxes.sqf", ["Medical",_spawnObject, _customBox, false]];
};

//Add automated supply box - yay!
_unit addAction ['Spawn Ammo Box', "MissionScripts\Logistics\LogiBoxes.sqf", ["Supply",_spawnObject, _customBox]];

//Verify if Ace is present before adding wheel & track spawn addactions
if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then {
    _unit addAction ['Spawn Spare Wheel', "MissionScripts\Logistics\LogiBoxes.sqf", ["Wheel", _spawnObject, _customBox]];
    _unit addAction ['Spawn Spare Track', "MissionScripts\Logistics\LogiBoxes.sqf", ["Track", _spawnObject, _customBox]];
};

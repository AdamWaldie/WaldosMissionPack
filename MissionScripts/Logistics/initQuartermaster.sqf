/*//    INFO TEXT    //// ==========================================================================================

This is used to setup the logistics spawning system, via the "Quartermaster". The quartermaster is an object or NPC which acts as the spawner for these supply boxes & equipment.

The call for this is as below:
[QuartermasterObject,SpawningObject,"SpawningCustomAmmobox"] call Waldo_fnc_SetupQuarterMaster; this disableAI "MOVE";

where the QuartermasterObject is the object the addaction is applied to. The SpawningObject is the object from which the box is spawned & the SpawningCustomAmmobox is the classname of a supply box you wish to use as the ammo box.
"SpawningCustomAmmobox" parameter must be put in speech marks, all else should not.

Examples:
[this,logisticsSpawn,"Box_IDAP_Equip_F"] call Waldo_fnc_SetupQuarterMaster; this disableAI "MOVE";

[this,logisticsSpawn,"Box_NATO_Ammo_F"] call Waldo_fnc_SetupQuarterMaster; this disableAI "MOVE";

These are from the exemplar mission
*/

params["_unit","_spawnObject",["_customBox",""]];
//Verify if Ace Medical is present, if so, enable ACE_Medical Box setup, else pass a vanialla support box to be filled with FirstAidKits & Medical Packs
if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then {
    _unit addAction ['Spawn Medical Box', Waldo_fnc_SpawnLogisticsBox, ["ACE_medicalSupplyCrate_advanced",_spawnObject, _customBox]];
} else {
    _unit addAction ['Spawn Medical Box', Waldo_fnc_SpawnLogisticsBox, ["Box_NATO_Support_F",_spawnObject, _customBox]];
};
_unit addAction ['Spawn Ammo Box', Waldo_fnc_SpawnLogisticsBox, [_customBox,_spawnObject, _customBox]];
_unit addAction ['Spawn Spare Wheel', Waldo_fnc_SpawnLogisticsBox, ["ACE_Wheel", _spawnObject, _customBox]];
_unit addAction ['Spawn Spare Track', Waldo_fnc_SpawnLogisticsBox, ["ACE_Track", _spawnObject, _customBox]];
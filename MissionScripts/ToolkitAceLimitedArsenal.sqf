/*
Purpose: Mission Production Tool to generate a limited ACE arsenal based off of the loadout of all playable units from a given side.
This is not designed to create a limited ace arsenal, but will output a readymade string to you to paste into inits.
Called From: Mission Maker debug
Execution time: NOT DURING MISSIONS
Author: Waldo
License: Distributable and editable with proper attribution.

/*================================MANUAL METHODOLOGY=========================

This can be used to make an Arsenal only with the items from your precreated loadouts. 
This is the best choice if you do not want to make a full arsenal available to have your Loadouts spawnable.

 I. Spawn the same amount of units as you have loadouts, give each unit one of them
 II. Start the mission then press ESC once loaded
 III. Clear the debug console then enter the following:

//Side unit collection

private _unitsBlufor = units blufor;
private _unitsOpfor = units opfor;
private _unitsIndependant = units independent;

//Get all loadouts of all sides

private _items = allUnits apply {getUnitLoadout _x};
_items = str _items splitString "[]," joinString ",";
_items = parseSimpleArray ("[" + _items + "]");
_items = _items arrayIntersect _items select {_x isEqualType "" && {_x != ""}};
copyToClipboard str _items;
*/
//Get all loadouts of blufor (Replace _unitsBlufor with equivilent for other sides)
private _unitsBlufor = units blufor;
private _items = _unitsBlufor apply {getUnitLoadout _x};
_items = str _items splitString "[]," joinString ",";
_items = parseSimpleArray ("[" + _items + "]");
_items = _items arrayIntersect _items select {_x isEqualType "" && {_x != ""}};
copyToClipboard str _items;
systemchat "Loadout Array of given side in clipboard";
/*

//When called by an object ingame
[_this, _items] call ace_arsenal_fnc_initBox


IV. Paste the created array from your clipboard into the space where the items are listed CTRL+V. The array is created with brackets.
Examples:

For a new Box: - [_box, ["item1", "item2", "itemN"]] call ace_arsenal_fnc_initBox

[this, ["item1", "item2", "itemN"]] call ace_arsenal_fnc_initBox

For an existing Box: - [_box, ["item1", "item2",

For an existing Box: - [_box, ["item1", "item2", "itemN"]] call ace_arsenal_fnc_addVirtualItems "itemN"]] call ace_arsenal_fnc_addVirtualItems


The mission pak mission has the following string of items:

[this,["rhs_weap_mk18_m320","rhsusf_acc_SFMB556","rhsusf_acc_ACOG_RMR","rhs_mag_30Rnd_556x45_M855A1_PMAG","rhs_mag_M433_HEDP","rhsusf_weap_glock17g4","hlc_acc_TLR1","rhsusf_mag_17Rnd_9x19_JHP","rhs_uniform_acu_oefcp","ACE_elasticBandage","ACE_MapTools","ACE_Flashlight_XL50","ACE_microDAGR","rhsusf_iotv_ocp_Squadleader","rhs_mag_m713_Red","rhs_mag_m714_White","B_AssaultPack_mcamo","ACRE_PRC152","rhsusf_ach_helmet_camo_ocp","ACE_Vector","ItemMap","ItemGPS","ItemRadio","ItemCompass","ItemWatch","rhs_weap_mk18_KAC_bk","rhsusf_acc_anpeq15side","rhsusf_acc_kac_grip","ACE_tourniquet","rhsusf_iotv_ocp_Medic","rhs_mag_30Rnd_556x45_Mk318_PMAG","rhs_mag_an_m8hc","rhs_mag_m67","B_Carryall_mcamo","ACE_salineIV","ACE_salineIV_250","ACE_salineIV_500","ACE_splint","plp_bo_w_BottleTequila","ACE_morphine","ACE_epinephrine","rhsusf_ach_helmet_headset_ess_ocp","ACE_EntrenchingTool","rhs_weap_m249_light_L","rhsusf_acc_anpeq15side_bk","rhsusf_100Rnd_556x45_mixed_soft_pouch","rhsusf_acc_grip4_bipod","rhsusf_iotv_ocp_Rifleman","rhsusf_100Rnd_556x45_soft_pouch","rhsusf_assault_eagleaiii_ocp","rhsusf_ach_helmet_ESS_ocp_alt","rhs_weap_mk18_KAC","rhsusf_acc_grip1","rhs_weap_M136_hp","rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red","rhsusf_mbav_grenadier","rhsusf_hgu56p_visor_mask_smiley"]] call ace_arsenal_fnc_initBox;

*/
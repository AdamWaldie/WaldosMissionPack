/*
 * Author: WaldoTheWarfighter
 * Validates every object classname and declared addon used by the shipped Eden compositions against
 * the currently loaded game configuration. This is an audit-only server check; it changes no world
 * state and emits one stable summary for automated/manual RPT review.
 *
 * Arguments: None.
 * Return Value: ARRAY - [missing CfgVehicles classes, missing CfgPatches addons].
 * Example: private _result = [] call compile preprocessFileLineNumbers "compositionCatalogueQA.sqf";
 * Current caller: full audit initServer.sqf.
 */

private _vehicleClasses = [
    "ACE_medicalSupplyCrate_advanced", "B_G_HMG_02_high_F", "B_HMG_01_high_F",
    "B_crew_F", "B_Helipilot_F", "B_Heli_Light_01_F", "B_Mortar_01_F", "B_MRAP_01_F", "B_Pilot_F", "B_Soldier_F", "B_Soldier_SL_F", "B_Soldier_TL_F", "B_supplyCrate_F",
    "B_T_VTOL_01_armed_F", "B_T_VTOL_01_infantry_F", "B_Truck_01_covered_F", "B_Truck_01_medical_F",
    "B_Truck_01_transport_F", "Box_NATO_Equip_F", "C_Van_01_transport_F", "Flag_Blue_F",
    "Flag_Red_F", "FlagPole_F", "Land_AirConditioner_03_F", "Land_BagBunker_Small_F",
    "Land_BagFence_Long_F", "Land_BagFence_Round_F", "Land_BagFence_Short_F",
    "Land_CampingChair_V2_F", "Land_CampingTable_F", "Land_Cargo_House_V1_F",
    "Land_City2_8m_F", "Land_Computer_01_sand_F", "Land_CzechHedgehog_01_new_F",
    "Land_Device_disassembled_F", "Land_GasTank_01_yellow_F", "Land_HBarrier_3_F",
    "Land_HelipadEmpty_F", "Land_InfoStand_V1_F", "Land_JumpTarget_F",
    "Land_Laptop_03_sand_F", "Land_Laptop_unfolded_F", "Land_MapBoard_F",
    "Land_MedicalTent_01_floor_dark_F", "Land_MedicalTent_01_NATO_generic_open_F",
    "Land_MultiScreenComputer_01_sand_F", "Land_Pallet_MilBoxes_F",
    "Land_PaperBox_open_empty_F", "Land_PortableCabinet_01_4drawers_sand_F",
    "Land_PortableCabinet_01_7drawers_sand_F", "Land_PortableCabinet_01_bookcase_sand_F",
    "Land_PortableDesk_01_sand_F", "Land_PortableServer_01_cover_sand_F",
    "EmptyDetector", "Land_PortableServer_01_sand_F", "Land_Router_01_sand_F", "Land_TTowerSmall_1_F",
    "Logic", "ModuleCurator_F", "ModuleRespawnPosition_F", "OmniDirectionalAntenna_01_sand_F",
    "SatelliteAntenna_01_Sand_F"
];
private _declaredAddons = [
    "A3_Air_F_Exp_VTOL_01", "A3_Air_F_Heli_Light_01", "A3_Characters_F", "A3_Characters_F_Mark", "A3_Modules_F",
    "A3_Modules_F_Curator_Curator", "A3_Modules_F_Multiplayer",
    "A3_Props_F_Enoch_Military_Camps", "A3_Props_F_Enoch_Military_Equipment",
    "A3_Props_F_Orange_Humanitarian_Camps", "A3_Soft_F_Beta_Truck_01",
    "A3_Soft_F_Exp_Truck_01", "A3_Soft_F_Gamma_Truck_01", "A3_Soft_F_Gamma_Van_01",
    "A3_Soft_F_MRAP_01", "A3_Static_F", "A3_Static_F_HMG_02", "A3_Static_F_Mortar_01",
    "A3_Structures_F_Civ_Camping", "A3_Structures_F_Civ_InfoBoards",
    "A3_Structures_F_Enoch_Military_Camps", "A3_Structures_F_EPA_Mil_Scrapyard",
    "A3_Structures_F_Exp_Industrial_Port", "A3_Structures_F_Ind_Transmitter_Tower",
    "A3_Structures_F_Items_Electronics", "A3_Structures_F_Mil_BagBunker",
    "A3_Structures_F_Mil_BagFence", "A3_Structures_F_Mil_Cargo",
    "A3_Structures_F_Mil_Flags", "A3_Structures_F_Mil_Fortification",
    "A3_Structures_F_Mil_Helipads", "A3_Structures_F_Orange_Humanitarian_Camps",
    "A3_Structures_F_Walls", "A3_Supplies_F_Exp_Ammoboxes", "A3_Weapons_F",
    "A3_Weapons_F_Acc", "A3_Weapons_F_Ammoboxes", "A3_Weapons_F_Items",
    "A3_Weapons_F_Pistols_P07", "A3_Weapons_F_Rifles_MX", "ace_attach", "ace_ballistics",
    "ace_cargo", "ace_chemlights", "ace_dragging", "ace_laserpointer", "ace_medical_engine",
    "ace_medical_treatment", "ace_nightvision", "ace_optics", "ace_realisticnames", "ace_scopes",
    "ace_sitting", "ace_smallarms", "acre_main", "acre_sys_prc117f", "acre_sys_prc152",
    "acre_sys_prc343"
];

private _missingClasses = _vehicleClasses select {!(isClass (configFile >> "CfgVehicles" >> _x))};
private _missingAddons = _declaredAddons select {!(isClass (configFile >> "CfgPatches" >> _x))};
diag_log format [
    "WMP COMPOSITION CATALOGUE QA: missingClasses=%1 %2 missingAddons=%3 %4",
    count _missingClasses,
    _missingClasses,
    count _missingAddons,
    _missingAddons
];
[_missingClasses, _missingAddons]

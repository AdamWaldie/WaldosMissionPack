/*
 * Author: WaldoTheWarfighter
 * Defines field-resupply, vehicle-recovery, object-scaling and logistics-crate defaults. World
 * mutation remains server-authoritative and object interactions remain client-local/JIP-safe.
 *
 * Schema: SHARED entries are [name, default]; SERVER entries are [name, default, publish BOOL].
 * CONDITIONAL entries are [scope, name, required CfgPatches class, loaded default, absent default,
 * publish BOOL]. Arguments: None. Return Value: HASHMAP consumed by the feature-config loader.
 *
 * Example: add compatible recovery package classes to Waldo_Recovery_PackageClasses.
 * Current callers: init.sqf (SHARED) and initServer.sqf (SERVER) through the loader.
 */
createHashMapFromArray [
    ["featureFamilies", ["Field Resupply", "Vehicle Recovery", "Object Scaling", "Logistics Crates"]],
    ["shared", [
        ["Waldo_FieldResupply_Enable", false],
        ["Waldo_FieldResupply_CrateClass", "Box_NATO_Ammo_F"],
        ["Waldo_FieldResupply_DefaultCarrierCapacity", 2],
        ["Waldo_FieldResupply_ChargesPerCrate", 5],
        ["Waldo_FieldResupply_MagazinesPerType", 1],
        ["Waldo_FieldResupply_UseCapacityBasedAmounts", true],
        ["Waldo_FieldResupply_CapacityAmounts", [4, 3, 8, 3, 2]],
        ["Waldo_FieldResupply_MinimumMagazineRounds", 2],
        ["Waldo_FieldResupply_AllowedMagazines", []],
        ["Waldo_FieldResupply_BlockedMagazines", []],
        ["Waldo_FieldResupply_RetainOnRespawn", true],
        ["Waldo_Recovery_ScanInterval", 3],
        ["Waldo_Recovery_NotificationRadius", 100],
        ["Waldo_Recovery_CreateWorkshopMarkers", true],
        ["Waldo_Recovery_PlacementClearance", 3],
        ["Waldo_Recovery_DefaultCustomVariables", []],
        ["Waldo_Recovery_PackageClasses", ["B_Slingload_01_Cargo_F", "Land_Pallet_MilBoxes_F"]]
    ]],
    ["server", [
        ["Waldo_ObjectScaling_Minimum", 0.1, false],
        ["Waldo_ObjectScaling_Maximum", 10, false],
        ["Waldo_ObjectScaling_AllowClientRequests", false, false],
        ["Logi_SupplyBoxClass", "B_supplyCrate_F", true]
    ]],
    ["conditional", [
        ["SERVER", "Logi_MedicalBoxClass", "ace_medical", "ACE_medicalSupplyCrate_advanced", "C_IDAP_supplyCrate_F", true]
    ]]
]

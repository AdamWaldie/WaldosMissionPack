/*
 * Author: WaldoTheWarfighter
 * Defines persistence defaults shared by server authority and player-local capture/apply code.
 * The INIDBI2 dependency gate and all database activity remain in persistence lifecycle functions.
 *
 * Schema: each SHARED entry is [missionNamespace variable name, guarded default value].
 * Arguments: None.
 * Return Value: HASHMAP consumed by Waldo_fnc_LoadFeatureConfigs.
 *
 * Example: edit SaveRadios to true to persist supported carried-radio state separately from loadouts.
 * Current caller: Waldo_fnc_LoadFeatureConfigs from init.sqf using the SHARED scope.
 */
createHashMapFromArray [
    ["featureFamilies", ["INIDBI2 Persistence"]],
    ["shared", [
        ["Waldo_Persistence_Enable", false],
        ["Waldo_Persistence_PlayerSaveInterval", 60],
        ["Waldo_Persistence_ObjectSaveInterval", 60],
        ["Waldo_Persistence_SaveLoadout", true],
        ["Waldo_Persistence_SaveMedical", true],
        ["Waldo_Persistence_SaveFoodWater", false],
        ["Waldo_Persistence_SavePosition", false],
        ["Waldo_Persistence_SaveRadios", false],
        ["Waldo_Persistence_DatabaseName", "WaldosMissionPack"],
        ["Waldo_Persistence_DefaultCustomVariables", [
            "Waldo_ObjectScale", "Waldo_ObjectScaleOriginal",
            "Waldo_Breaching_Processed", "Waldo_Breaching_AccumulatedStrength",
            "Waldo_FieldResupply_Hub", "Waldo_FieldResupply_Stock",
            "Waldo_FieldResupply_Deployed", "Waldo_FieldResupply_Charges"
        ]]
    ]]
]

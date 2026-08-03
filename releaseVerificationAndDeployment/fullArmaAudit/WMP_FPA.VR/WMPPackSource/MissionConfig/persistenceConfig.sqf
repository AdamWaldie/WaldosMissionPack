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
 *
 * CUSTOMISATION GUIDE:
 * MISSION MAKER - Enable and the Save* switches define the campaign contract and should be reviewed
 * per mission. DatabaseName separates campaigns; changing it starts a different logical save set.
 * SavePosition is deliberately false because restoring an old position can bypass mission flow.
 * SaveRadios is deliberately false unless radio-state persistence is part of the mission design.
 * ADVANCED TUNING - save intervals are seconds and should normally remain 60. Lower values increase
 * database traffic. DefaultCustomVariables is an allowlist of object variables that survive package
 * or persistence restoration; add only serialisable, intentionally persistent state.
 */
createHashMapFromArray [
    ["featureFamilies", ["INIDBI2 Persistence"]],
    ["shared", [
        // MISSION MAKER: campaign persistence policy.
        ["Waldo_Persistence_Enable", false],              // Requires a working server INIDBI2 extension.
        ["Waldo_Persistence_SaveLoadout", true],          // Restore filtered inventory/loadout.
        ["Waldo_Persistence_SaveMedical", true],          // Restore supported ACE medical state.
        ["Waldo_Persistence_SaveFoodWater", false],       // Restore supported survival state.
        ["Waldo_Persistence_SavePosition", false],        // Restore position; may bypass mission progression.
        ["Waldo_Persistence_SaveRadios", false],          // Restore supported ACRE radio state separately.
        ["Waldo_Persistence_DatabaseName", "WaldosMissionPack"], // Stable campaign/database key.
        // ADVANCED TUNING: database cadence and serialised object state.
        ["Waldo_Persistence_PlayerSaveInterval", 60],     // Seconds; lower means more writes.
        ["Waldo_Persistence_ObjectSaveInterval", 60],     // Seconds; lower means more writes.
        ["Waldo_Persistence_DefaultCustomVariables", [
            "Waldo_ObjectScale", "Waldo_ObjectScaleOriginal",
            "Waldo_Breaching_Processed", "Waldo_Breaching_AccumulatedStrength",
            "Waldo_FieldResupply_Hub", "Waldo_FieldResupply_Stock",
            "Waldo_FieldResupply_Deployed", "Waldo_FieldResupply_Charges"
        ]]
    ]]
]

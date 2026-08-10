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
 * Result: supported per-player radio state may cross sessions when the INIDBI2 gate is ready.
 * Current caller: Waldo_fnc_LoadFeatureConfigs from init.sqf using the SHARED scope.
 *
 * ACTIVATION MODEL: AUTOMATIC WHEN ENABLED, SUBJECT TO THE SERVER DEPENDENCY GATE.
 * WMP starts server and player persistence itself. A working server-side INIDBI2 extension is still
 * mandatory; enabled does not mean available, and the feature remains inactive if the gate fails.
 * Player state needs no custom registration. World objects must be registered with stable keys.
 *
 * EDIT FOR A NORMAL MISSION: Enable, Save* policy, DatabaseName and Scope.
 * LEAVE ALONE UNLESS EXTENDING/TESTING: save intervals and DefaultCustomVariables.
 * CUSTOM CALLS: register pre-placed
 * persistent objects from initServer.sqf with Waldo_fnc_PersistenceRegisterObject after enabling;
 * the function queues early server registrations until the database lifecycle becomes active.
 *
 * CUSTOMISATION GUIDE:
 * MISSION MAKER - Enable and the Save* switches define the campaign contract and should be reviewed
 * per mission. DatabaseName names the save collection. Scope controls whether WMP adds the
 * current mission and terrain to that name. Keep MISSION unless several missions intentionally
 * share one campaign record; choose CAMPAIGN only for that deliberate cross-mission use case.
 * SavePosition is deliberately false because restoring an old position can bypass mission flow.
 * SaveRadios is deliberately false unless radio-state persistence is part of the mission design.
 * ADVANCED TUNING - save intervals are seconds and should normally remain 60. Lower values increase
 * database traffic. DefaultCustomVariables is an allowlist of object variables that survive package
 * or persistence restoration; add only serialisable, intentionally persistent state.
 *
 * HOW TO READ THE DATA BELOW:
 * Every `shared` row is `[variable name, guarded default]`. The loader installs it only when no
 * earlier mission value exists. Enable requests persistence but the server INIDBI2 dependency gate
 * decides availability; clients cannot make the database ready by changing this variable locally.
 *
 * LOADOUTS AND PLAYER-LEVEL ACRE STATE:
 * The normal mission `Waldo_fnc_SaveLoadout` always treats inventory plus supported ACRE settings as
 * one local respawn snapshot. Transient `_ID_n` items become base classes in the inventory, while
 * channel/frequency, ear, volume, supported audio mode and selected radio are saved separately and
 * restored after fresh IDs exist. `Waldo_Persistence_SaveLoadout` controls whether that filtered
 * inventory crosses sessions through INIDBI2. SaveRadios controls whether the corresponding radio
 * state also crosses sessions. When true, WMP captures each supported carried radio by
 * `[base radio class, same-type occurrence]`, plus channel/frequency, spatial ear, volume, supported
 * audio mode and selected radio. After the filtered loadout creates fresh unique IDs, that player's
 * saved state is restored onto the matching new instances and becomes the local respawn snapshot.
 * This is per-player state, not data embedded in an inventory classname. If SaveRadios is false,
 * persistence restores the authored ACRE baseline, but subsequent local loadout saves still retain
 * the player's chosen settings for ordinary respawns.
 * On join/JIP, automatic player writes remain locked until the server explicitly reports FOUND or
 * NONE and the corresponding saved radios or authored baseline are ready. FAILED or a 30-second
 * timeout releases ordinary mission/ACRE startup but keeps persistence writes locked, so an unread
 * database record cannot be replaced by the temporary starting loadout.
 *
 * SETTING-BY-SETTING GUIDE:
 * - Waldo_Persistence_Enable (MISSION MAKER): requests persistence; no save occurs unless the server INIDBI2 gate passes.
 * - Waldo_Persistence_SaveLoadout (MISSION MAKER): stores filtered player inventory across sessions.
 * - Waldo_Persistence_SaveMedical (MISSION MAKER): stores/restores supported ACE medical state.
 * - Waldo_Persistence_SaveFoodWater (MISSION MAKER): stores supported survival values when their system exists.
 * - Waldo_Persistence_SavePosition (MISSION MAKER): restores the old position; false avoids bypassing mission flow.
 * - Waldo_Persistence_SaveRadios (MISSION MAKER): persists supported per-player ACRE settings separately from inventory.
 * - Waldo_Persistence_DatabaseName (MISSION MAKER): stable save collection name; changing it begins a separate dataset.
 * - Waldo_Persistence_Scope (MISSION MAKER): MISSION isolates by mission/terrain; CAMPAIGN deliberately shares records.
 * - Waldo_Persistence_PlayerSaveInterval (ADVANCED): seconds between automatic player writes; lower increases I/O.
 * - Waldo_Persistence_ObjectSaveInterval (ADVANCED): seconds between registered-world-object writes.
 * - Waldo_Persistence_DefaultCustomVariables (ADVANCED): serialisable object-variable names saved for every object.
 *
 * BEGINNER EXAMPLE: install INIDBI2 on the server, change Enable to true, leave Scope as MISSION,
 * and keep SavePosition/SaveRadios false for the first test. A successful diagnostics report must
 * say that the runtime extension is available; the config switch alone is not proof. Register a
 * world object with a stable key only when it also needs persistence. Changing DatabaseName or
 * Scope later intentionally selects different records rather than migrating old data.
 */
createHashMapFromArray [
    ["featureFamilies", ["INIDBI2 Persistence"]],
    ["shared", [
        // MISSION MAKER: campaign persistence policy.
        ["Waldo_Persistence_Enable", false],              // Requires a working server INIDBI2 extension.
        ["Waldo_Persistence_SaveLoadout", true],          // Filter unique ACRE IDs, then restore ordinary inventory.
        ["Waldo_Persistence_SaveMedical", true],          // Restore supported ACE medical state.
        ["Waldo_Persistence_SaveFoodWater", false],       // Restore supported survival state.
        ["Waldo_Persistence_SavePosition", false],        // Restore position; may bypass mission progression.
        ["Waldo_Persistence_SaveRadios", false],          // Per-player radio state; see ordering/identity above.
        ["Waldo_Persistence_DatabaseName", "WaldosMissionPack"], // Stable campaign/database key.
        ["Waldo_Persistence_Scope", "MISSION"],          // MISSION isolates player/object saves; CAMPAIGN deliberately shares them.
        // ADVANCED TUNING: database cadence and serialised object state.
        ["Waldo_Persistence_PlayerSaveInterval", 60],     // Seconds; lower means more writes.
        ["Waldo_Persistence_ObjectSaveInterval", 60],     // Seconds; lower means more writes.
        ["Waldo_Persistence_DefaultCustomVariables", [ // ARRAY of serialisable object-variable name strings.
            "Waldo_ObjectScale", "Waldo_ObjectScaleOriginal",
            "Waldo_Breaching_Processed", "Waldo_Breaching_AccumulatedStrength",
            "Waldo_FieldResupply_Hub", "Waldo_FieldResupply_Stock",
            "Waldo_FieldResupply_Deployed", "Waldo_FieldResupply_Charges"
        ]]
    ]]
]

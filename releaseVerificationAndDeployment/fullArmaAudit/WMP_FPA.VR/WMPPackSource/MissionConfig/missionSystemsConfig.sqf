/*
 * Author: WaldoTheWarfighter
 * Defines squad-rally, economy, minigame, corpse-trap, ACE logistics, diagnostics and safestart
 * defaults. Activation, event handlers, state mutation and safestart application remain in init.
 *
 * Schema: SHARED entries are [name, default]; SERVER entries are [name, default, publish BOOL].
 * Arguments: None. Return Value: HASHMAP consumed by Waldo_fnc_LoadFeatureConfigs.
 *
 * Example: leave Waldo_SafeStart_AutoStart false to begin live, then use the Zeus
 * "SafeStart: Enable Protection" module if the mission needs to be paused safely in progress.
 * Result: no protection is applied at mission start, but every runtime control remains available.
 * Current callers: init.sqf (SHARED) and initServer.sqf (SERVER) through the loader.
 *
 * ACTIVATION MODEL: AUTOMATIC WHEN ENABLED, WITH FEATURE-SPECIFIC CONTENT.
 * Rally, minigames, corpse traps, diagnostics and Safestart controls load through the existing
 * lifecycle. Loading SafeStart controls does not activate protection when AutoStart is false.
 * Economy enablement starts its runtime, but economy resources/catalogues still come from the
 * dedicated economy setup/presets. The ACE values here are global policy, not separate features.
 *
 * EDIT FOR A NORMAL MISSION: rally rules, optional-system switches, diagnostics and safestart.
 * LEAVE ALONE UNLESS EXTENDING/TESTING: safe-position search and global ACE handling values.
 * CUSTOM CALLS: none for normal activation. Use each feature's documented runtime control API/ZEN
 * module for mid-mission changes; do not repeat its startup function in mission init files.
 *
 * CUSTOMISATION GUIDE:
 * MISSION MAKER - rally/economy/minigame/corpse-trap enablement, rally object and gameplay rules,
 * diagnostics and safestart policy should be reviewed per mission. Rally duration/deployment/cooldown
 * are seconds, distances are metres, slope is degrees and minimum members includes the leader.
 * SafeStart_ZoneMarker is an existing marker name; blank uses Radius around the configured origin.
 * ADVANCED TUNING - rally clearance/search geometry and ACE drag/carry/hearing values affect engine
 * interactions globally. The shipped ACE values preserve established pack behavior and should not
 * be changed merely because they are exposed. RunDiagnostics may be disabled only after setup is
 * verified. SafeStart values are server-owned and later runtime module changes remain authoritative.
 *
 * HOW TO READ THE DATA BELOW:
 * `shared` rows are `[variable, guarded default]` on all machines. `server` rows are
 * `[variable, guarded default, publish]`; publish true is replayed to clients/JIP and false remains
 * server-only. Enabling a feature activates its lifecycle but does not invent required catalogue,
 * marker or object content. Values under the ACE heading are global ACE policy, not WMP modules.
 *
 * SETTING-BY-SETTING GUIDE - SQUAD RALLY:
 * - Waldo_Rally_Enable (MISSION MAKER): installs the eligible squad-leader self-action when true.
 * - Waldo_Rally_ObjectClass (MISSION MAKER): valid CfgVehicles object used as the deployed rally.
 * - Waldo_Rally_Duration (MISSION MAKER): active lifetime in seconds; use a positive value.
 * - Waldo_Rally_DeploymentTime (MISSION MAKER): uninterrupted placement action duration in seconds.
 * - Waldo_Rally_Cooldown (MISSION MAKER): group delay after pack-up/expiry before another deployment.
 * - Waldo_Rally_EnemyExclusionRadius (MISSION MAKER): hostile units within this many metres block placement.
 * - Waldo_Rally_MinimumGroupMembers (MISSION MAKER): living members required, including the leader.
 * - Waldo_Rally_PlacementDistance (MISSION MAKER): requested object distance ahead of the leader.
 * - Waldo_Rally_MaximumSlope (MISSION MAKER): steepest accepted terrain angle in degrees.
 * - Waldo_Rally_RespawnClearance (ADVANCED): empty radius required around a chosen respawn position.
 * - Waldo_Rally_RespawnSearchDistance (ADVANCED): maximum radius searched for an open respawn position.
 * - Waldo_Rally_AllowRegroup (MISSION MAKER): permits the runtime's optional regroup/redeploy behaviour.
 *
 * SETTING-BY-SETTING GUIDE - OPTIONAL SYSTEMS AND ACE POLICY:
 * - Waldo_Economy_Enable (MISSION MAKER): starts economy runtime; resources/catalogues still need setup.
 * - Waldo_MiniGames_Enable (MISSION MAKER): permits registered interaction-equipment challenges.
 * - Waldo_CorpseTraps_Enable (MISSION MAKER): permits corpse-trap handling where traps are configured.
 * - ACE_maxWeightDrag (GLOBAL ACE POLICY): maximum draggable mass; 10000 preserves permissive pack behaviour.
 * - ACE_maxWeightCarry (GLOBAL ACE POLICY): maximum carryable mass; 6000 preserves pack behaviour.
 * - ace_hearing_disableVolumeUpdate (GLOBAL ACE POLICY): retain true unless deliberately changing ACE hearing globally.
 *
 * SETTING-BY-SETTING GUIDE - DIAGNOSTICS AND SAFESTART:
 * - Waldo_RunDiagnostics (MISSION MAKER): runs setup/lifecycle diagnostics; keep true while building/testing.
 * - Waldo_SafeStart_Confine (MISSION MAKER): when protection is active, keep players inside the configured area.
 * - Waldo_SafeStart_Radius (MISSION MAKER): fallback circular radius when ZoneMarker is blank.
 * - Waldo_SafeStart_ZoneMarker (MISSION MAKER): existing marker name used as confinement area; "" uses Radius.
 * - Waldo_SafeStart_AutoStart (MISSION MAKER): false starts live; Zeus may still enable protection mid-mission.
 *
 * BEGINNER RALLY TEST: set Enable true and leave the remaining rally defaults unchanged. Use a
 * group leader in a living two-person group, move more than 100 m from enemies, and use the Squad
 * Rally self-action on terrain below 20 degrees. The safe-position settings affect where players
 * reappear, not where the visible rally object is initially requested.
 */
createHashMapFromArray [
    ["featureFamilies", ["Squad Rally", "Economy", "Mini Games", "Corpse Traps", "ACE Logistics", "Diagnostics", "Safestart"]],
    ["shared", [
        // MISSION MAKER: squad-rally availability, object, timing and placement rules.
        ["Waldo_Rally_Enable", false],              // BOOL: install eligible squad-leader self interaction.
        ["Waldo_Rally_ObjectClass", "Land_SatelliteAntenna_01_F"], // CfgVehicles deployed rally object.
        ["Waldo_Rally_Duration", 180],              // SECONDS: positive rally lifetime; 0 expires immediately and is invalid setup.
        ["Waldo_Rally_DeploymentTime", 15],         // SECONDS: uninterrupted placement progress.
        ["Waldo_Rally_Cooldown", 300],              // SECONDS: group wait after pack-up/expiry before redeploy.
        ["Waldo_Rally_EnemyExclusionRadius", 100],  // METRES: hostile presence refuses placement.
        ["Waldo_Rally_MinimumGroupMembers", 2],     // COUNT: living group members including leader.
        ["Waldo_Rally_PlacementDistance", 2],       // METRES: requested object position ahead of leader.
        ["Waldo_Rally_MaximumSlope", 20],           // DEGREES: maximum accepted terrain slope.
        ["Waldo_Rally_RespawnClearance", 2.5],       // ADVANCED safe-position clearance in metres.
        ["Waldo_Rally_RespawnSearchDistance", 15],  // ADVANCED maximum safe-position search radius.
        ["Waldo_Rally_AllowRegroup", false],        // BOOL: permit redeploy behavior defined by rally runtime.
        // MISSION MAKER: optional pack systems.
        ["Waldo_Economy_Enable", false],            // BOOL: runtime only; catalogue/resources require economy setup.
        ["Waldo_MiniGames_Enable", true],           // BOOL: allow registered interaction-equipment challenges.
        ["Waldo_CorpseTraps_Enable", false],        // BOOL: enable corpse-trap handling where configured.
        // ADVANCED global ACE behavior; normally retain pack defaults.
        ["ACE_maxWeightDrag", 10000],               // ACE mass limit; pack-established permissive drag policy.
        ["ACE_maxWeightCarry", 6000],               // ACE mass limit; pack-established permissive carry policy.
        ["ace_hearing_disableVolumeUpdate", true]   // BOOL: preserve established ACE hearing volume behavior.
    ]],
    ["server", [
        // MISSION MAKER: server diagnostics and safestart contract; JIP-published.
        ["Waldo_RunDiagnostics", true, true],       // BOOL: run pack configuration/lifecycle diagnostics.
        ["Waldo_SafeStart_Confine", false, true],   // BOOL: keep players inside configured start area while active.
        ["Waldo_SafeStart_Radius", 150, false],     // METRES: fallback confinement radius when marker is blank.
        ["Waldo_SafeStart_ZoneMarker", "", false], // STRING: existing area marker name; blank selects radius mode.
        ["Waldo_SafeStart_AutoStart", false, true]  // BOOL: false starts live (default); Zeus can enable protection later.
    ]]
]

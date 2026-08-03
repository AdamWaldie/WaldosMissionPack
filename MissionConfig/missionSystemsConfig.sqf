/*
 * Author: WaldoTheWarfighter
 * Defines squad-rally, economy, minigame, corpse-trap, ACE logistics, diagnostics and safestart
 * defaults. Activation, event handlers, state mutation and safestart application remain in init.
 *
 * Schema: SHARED entries are [name, default]; SERVER entries are [name, default, publish BOOL].
 * Arguments: None. Return Value: HASHMAP consumed by Waldo_fnc_LoadFeatureConfigs.
 *
 * Example: set Waldo_SafeStart_AutoStart false to ship live while retaining runtime controls.
 * Current callers: init.sqf (SHARED) and initServer.sqf (SERVER) through the loader.
 *
 * ACTIVATION MODEL: AUTOMATIC WHEN ENABLED, WITH FEATURE-SPECIFIC CONTENT.
 * Rally, minigames, corpse traps, diagnostics and safestart start through the existing lifecycle.
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
 */
createHashMapFromArray [
    ["featureFamilies", ["Squad Rally", "Economy", "Mini Games", "Corpse Traps", "ACE Logistics", "Diagnostics", "Safestart"]],
    ["shared", [
        // MISSION MAKER: squad-rally availability, object, timing and placement rules.
        ["Waldo_Rally_Enable", false],
        ["Waldo_Rally_ObjectClass", "Land_SatelliteAntenna_01_F"],
        ["Waldo_Rally_Duration", 180],
        ["Waldo_Rally_DeploymentTime", 15],
        ["Waldo_Rally_Cooldown", 300],
        ["Waldo_Rally_EnemyExclusionRadius", 100],
        ["Waldo_Rally_MinimumGroupMembers", 2],
        ["Waldo_Rally_PlacementDistance", 2],
        ["Waldo_Rally_MaximumSlope", 20],
        ["Waldo_Rally_RespawnClearance", 2.5],       // ADVANCED safe-position clearance in metres.
        ["Waldo_Rally_RespawnSearchDistance", 15],  // ADVANCED maximum safe-position search radius.
        ["Waldo_Rally_AllowRegroup", false],
        // MISSION MAKER: optional pack systems.
        ["Waldo_Economy_Enable", false],
        ["Waldo_MiniGames_Enable", true],
        ["Waldo_CorpseTraps_Enable", false],
        // ADVANCED global ACE behavior; normally retain pack defaults.
        ["ACE_maxWeightDrag", 10000],
        ["ACE_maxWeightCarry", 6000],
        ["ace_hearing_disableVolumeUpdate", true]
    ]],
    ["server", [
        // MISSION MAKER: server diagnostics and safestart contract; JIP-published.
        ["Waldo_RunDiagnostics", true, true],
        ["Waldo_SafeStart_Confine", false, true],
        ["Waldo_SafeStart_Radius", 150, false],
        ["Waldo_SafeStart_ZoneMarker", "", false],
        ["Waldo_SafeStart_AutoStart", true, true]
    ]]
]

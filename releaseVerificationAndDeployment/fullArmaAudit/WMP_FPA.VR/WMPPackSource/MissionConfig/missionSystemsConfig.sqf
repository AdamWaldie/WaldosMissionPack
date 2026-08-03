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
 */
createHashMapFromArray [
    ["featureFamilies", ["Squad Rally", "Economy", "Mini Games", "Corpse Traps", "ACE Logistics", "Diagnostics", "Safestart"]],
    ["shared", [
        ["Waldo_Rally_Enable", false],
        ["Waldo_Rally_ObjectClass", "Land_SatelliteAntenna_01_F"],
        ["Waldo_Rally_Duration", 180],
        ["Waldo_Rally_DeploymentTime", 15],
        ["Waldo_Rally_Cooldown", 300],
        ["Waldo_Rally_EnemyExclusionRadius", 100],
        ["Waldo_Rally_MinimumGroupMembers", 2],
        ["Waldo_Rally_PlacementDistance", 2],
        ["Waldo_Rally_MaximumSlope", 20],
        ["Waldo_Rally_RespawnClearance", 2.5],
        ["Waldo_Rally_RespawnSearchDistance", 15],
        ["Waldo_Rally_AllowRegroup", false],
        ["Waldo_Economy_Enable", false],
        ["Waldo_MiniGames_Enable", true],
        ["Waldo_CorpseTraps_Enable", false],
        ["ACE_maxWeightDrag", 10000],
        ["ACE_maxWeightCarry", 6000],
        ["ace_hearing_disableVolumeUpdate", true]
    ]],
    ["server", [
        ["Waldo_RunDiagnostics", true, true],
        ["Waldo_SafeStart_Confine", true, true],
        ["Waldo_SafeStart_Radius", 75, true],
        ["Waldo_SafeStart_ZoneMarker", "", true],
        ["Waldo_SafeStart_AutoStart", true, true]
    ]]
]

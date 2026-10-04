/*
 * Author: WaldoTheWarfighter
 * CUSTOMISATION GUIDE FOR THE MISSION MAKER: Edit the shared skill profile values below. Tactical AI behaviour belongs
 * to the standalone Waldos AI Tweaks mod.
 * ACTIVATION MODEL: AUTOMATIC WHEN ENABLED. WMP applies values to eligible local AI and reapplies
 * them after locality changes.
 * EDIT FOR A NORMAL MISSION: Choose the profile, day/night mode, apply mode and inclusion filters.
 * ADVANCED: Skill variance and restore-on-stop alter how profiles are applied and removed.
 * LEAVE ALONE UNLESS EXTENDING/TESTING: Profile display names and empty class/faction filters.
 * CUSTOM CALLS: Runtime changes should use the WMP AI_CONFIG control path so the server broadcasts
 * one authoritative choice. Direct skill scripts remain available for mission-authored exceptions.
 * HOW TO READ THE DATA BELOW: Each row is [setting name, default value].
 * Purpose: Defines the mission-pack AI skill-value profiles retained after tactical AI behaviour
 * moved to Waldos AI Tweaks.
 * Locality / Authority: Loaded on every machine. The server publishes runtime choices; each machine
 * applies them only to AI units it owns.
 * Repeat/JIP: Guarded defaults never replace live server/JIP values. Locality handlers reapply the
 * selected skill values after ownership migration.
 * Arguments: None.
 * Return Value: HASHMAP consumed by the feature-config loader.
 * Current callers: Waldo_fnc_LoadFeatureConfigs during mission initialization.
 * Example: Set Waldo_AIRebalance_Profile to "VETERAN" before init to use veteran skill values.
 */

createHashMapFromArray [
    ["featureFamilies", ["AI Skill Values"]],
    ["shared", [
        ["Waldo_AIRebalance_Enable", true],
        ["Waldo_AIRebalance_Profile", "LINE"],
        ["Waldo_AIRebalance_Mode", "DAY"],
        ["Waldo_AI_ApplyMode", "BOTH"],
        ["Waldo_AI_RestoreOnStop", true],
        ["Waldo_AI_SkillVariance", 0],
        ["Waldo_AI_IncludedSides", []],
        ["Waldo_AI_IncludedFactions", []],
        ["Waldo_AI_ExcludedFactions", []],
        ["Waldo_AI_ExcludedClasses", []],
        ["Waldo_AI_ProfileDisplayNames", createHashMapFromArray [
            ["LEGACY", "Existing Mission Balance"], ["MILITIA", "WMP Militia"],
            ["LINE", "WMP Line"], ["VETERAN", "WMP Veteran"], ["ELITE", "WMP Elite"]
        ]]
    ]]
]

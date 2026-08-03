/*
 * Author: WaldoTheWarfighter
 * Defines AI rebalance selection, filters, display names and improved helicopter-landing control
 * limits. AI application and locality migration remain in MissionScripts\AiScripting.
 *
 * Schema: SHARED entries are [missionNamespace variable name, guarded default value].
 * Arguments: None.
 * Return Value: HASHMAP consumed by Waldo_fnc_LoadFeatureConfigs.
 *
 * Example: change Waldo_AIRebalance_Profile from LINE to MILITIA, VETERAN or ELITE.
 * Current caller: Waldo_fnc_LoadFeatureConfigs from init.sqf using the SHARED scope.
 *
 * CUSTOMISATION GUIDE:
 * MISSION MAKER - enable, Profile, Mode and include/exclude filters are intended choices. Profiles
 * are MILITIA, LINE, VETERAN or ELITE; LINE is the WMP default for editor and Zeus AI. Mode is DAY
 * or NIGHT. ApplyMode is BOTH, EXISTING or NEW. Side filters use WEST, EAST, GUER or CIV; faction
 * and class filters use config classnames. Empty include arrays mean unrestricted.
 * ADVANCED TUNING - SkillVariance, RestoreOnStop and every ImprovedHelicopterLanding numeric value
 * are control/safety parameters. Keep defaults unless a repeatable aircraft/terrain test requires
 * adjustment. Distances/heights are metres, rates are metres/second, intervals/times are seconds.
 * COMPATIBILITY - Waldo_AIRebalance_Mode may fall back from Waldo_AI_Mode; configure the new name.
 */
createHashMapFromArray [
    ["featureFamilies", ["AI Rebalance", "Improved AI Helicopter Landings"]],
    ["shared", [
        // MISSION MAKER: AI population, profile and filtering policy.
        ["Waldo_AIRebalance_Enable", true],
        ["Waldo_AIRebalance_Profile", "LINE"],
        ["Waldo_AI_ApplyMode", "BOTH"],
        ["Waldo_AI_RestoreOnStop", true],            // ADVANCED: restore captured vanilla/mission skills on stop.
        ["Waldo_AI_SkillVariance", 0],               // ADVANCED: random skill offset; 0 is deterministic.
        ["Waldo_AI_IncludedSides", []],
        ["Waldo_AI_IncludedFactions", []],
        ["Waldo_AI_ExcludedFactions", []],
        ["Waldo_AI_ExcludedClasses", []],
        // MISSION MAKER master switch followed by ADVANCED landing-controller tuning.
        ["Waldo_ImprovedHelicopterLanding_Enable", true],
        ["Waldo_ImprovedHelicopterLanding_MinimumActivationDistance", 50],
        ["Waldo_ImprovedHelicopterLanding_TriggerDistance", 500],
        ["Waldo_ImprovedHelicopterLanding_TriggerSpeedFactor", 4.2],
        ["Waldo_ImprovedHelicopterLanding_TransitAltitude", 30],
        ["Waldo_ImprovedHelicopterLanding_GlideSlopeRatio", 4],
        ["Waldo_ImprovedHelicopterLanding_TreeScanRadius", 25],
        ["Waldo_ImprovedHelicopterLanding_TreeSafetyBuffer", 5],
        ["Waldo_ImprovedHelicopterLanding_MaximumTreeHoverHeight", 40],
        ["Waldo_ImprovedHelicopterLanding_GoAroundTriggerDistance", 200],
        ["Waldo_ImprovedHelicopterLanding_GoAroundHeight", 150],
        ["Waldo_ImprovedHelicopterLanding_GoAroundExitDistance", 250],
        ["Waldo_ImprovedHelicopterLanding_GoAroundSpeed", 70],
        ["Waldo_ImprovedHelicopterLanding_MaximumGoArounds", 1],
        ["Waldo_ImprovedHelicopterLanding_MaximumClimbRate", 8],
        ["Waldo_ImprovedHelicopterLanding_MaximumDescentRate", 10],
        ["Waldo_ImprovedHelicopterLanding_TouchdownRadius", 2],
        ["Waldo_ImprovedHelicopterLanding_FinalCommitDistance", 75],
        ["Waldo_ImprovedHelicopterLanding_ControlInterval", 0.05],
        ["Waldo_ImprovedHelicopterLanding_TouchdownHoldSeconds", 8],
        ["Waldo_AI_ProfileDisplayNames", createHashMapFromArray [ // ADVANCED: labels only; keys are implementation IDs.
            ["LEGACY", "Existing Mission Balance"], ["MILITIA", "WMP Militia"],
            ["LINE", "WMP Line"], ["VETERAN", "WMP Veteran"], ["ELITE", "WMP Elite"]
        ]]
    ]],
    ["fallbacks", [["SHARED", "Waldo_AIRebalance_Mode", "Waldo_AI_Mode", "DAY"]]]
]

/*
 * Author: WaldoTheWarfighter
 * Defines hazardous-environment, tree-felling and explosive-breaching defaults. Zone/object
 * registration and damage/replacement execution remain in their locality-aware feature scripts.
 *
 * Schema: SHARED entries are [missionNamespace variable name, guarded default value].
 * Arguments: None. Return Value: HASHMAP consumed by Waldo_fnc_LoadFeatureConfigs.
 *
 * Example: add a named hazard preset HashMap or map a mod explosive ammo class to its strength.
 * Current caller: Waldo_fnc_LoadFeatureConfigs from init.sqf using the SHARED scope.
 *
 * CUSTOMISATION GUIDE:
 * MISSION MAKER - enable switches, named hazard presets, axe/tool class patterns, fallen-object
 * pools, protected areas/yields and breaching profiles/explosive strengths are mission content.
 * Hazard types are free stable IDs consumed by profiles (shipped examples HAZARD and NO_OXYGEN).
 * Each damage threshold is [exposure, damage fraction]; fatalExposure is seconds/exposure units.
 * Tree DirectionMode is RANDOM or TOOL; RegrowSeconds -1 disables regrowth.
 * ADVANCED TUNING - hazard tick interval, exposure rate/decay, tree hit/cooldown/size geometry and
 * bush clearance affect scheduler cadence or world mutation. Test non-default values on the actual
 * terrain and use only existing classnames. Damage fractions must remain 0-1.
 */
createHashMapFromArray [
    ["featureFamilies", ["Hazardous Environments", "Tree Felling", "Explosive Breaching"]],
    ["shared", [
        // MISSION MAKER master switch; ADVANCED cadence/presentation defaults.
        ["Waldo_Hazard_Enable", false],
        ["Waldo_Hazard_Interval", 1],
        ["Waldo_Hazard_ShowStatus", true],
        ["Waldo_Hazard_NotifyTransitions", true],
        ["Waldo_Hazard_NotificationDuration", 6],
        // MISSION MAKER: reusable RP/gameplay profiles; zones may override individual keys.
        ["Waldo_Hazard_Presets", createHashMapFromArray [
            ["MILD", createHashMapFromArray [
                ["type", "HAZARD"], ["label", "Hazardous Area"], ["rate", 0.5], ["decay", 0.25],
                ["damageType", "stab"], ["damageThresholds", [[20, 0.01], [45, 0.02]]],
                ["damageStageMessages", ["Continued exposure is causing injury.", "Exposure is becoming severe; evacuate or use protection."]]
            ]],
            ["SEVERE", createHashMapFromArray [
                ["type", "HAZARD"], ["label", "Severe Hazard"], ["rate", 2], ["decay", 0.1],
                ["damageType", "stab"], ["damageThresholds", [[8, 0.03], [20, 0.08], [35, 0.15]]], ["fatalExposure", 60],
                ["damageStageMessages", ["Hazard exposure is causing injury.", "Severe exposure: evacuate immediately.", "Critical exposure: death is imminent."]]
            ]],
            ["VACUUM", createHashMapFromArray [
                ["type", "NO_OXYGEN"], ["label", "Unpressurised Area"], ["rate", 8], ["decay", 2],
                ["protectInVehicles", true], ["vehicleFactor", 0], ["damageType", "stab"],
                ["damageThresholds", [[8, 0.04], [20, 0.12]]], ["fatalExposure", 35],
                ["damageStageMessages", ["Oxygen deprivation is causing injury.", "Critical oxygen deprivation: reach pressure immediately."]]
            ]]
        ]],
        // MISSION MAKER enablement/content with ADVANCED hit and world-geometry tuning.
        ["Waldo_TreeFelling_Enable", false],
        ["Waldo_TreeFelling_Range", 3],
        ["Waldo_TreeFelling_BaseHits", 3],
        ["Waldo_TreeFelling_HeightFactor", 0.25],
        ["Waldo_TreeFelling_HitCooldown", 0.7],
        ["Waldo_TreeFelling_WeaponPatterns", ["axe", "hatchet"]],
        ["Waldo_TreeFelling_FallenClasses", ["Land_WoodenLog_F"]],
        ["Waldo_TreeFelling_FallenClassesSmall", []],
        ["Waldo_TreeFelling_FallenClassesMedium", []],
        ["Waldo_TreeFelling_FallenClassesLarge", []],
        ["Waldo_TreeFelling_SizeThresholds", [7, 15]],
        ["Waldo_TreeFelling_FallenRandomDirection", true],
        ["Waldo_TreeFelling_DirectionMode", "RANDOM"],
        ["Waldo_TreeFelling_ClearBushes", false],
        ["Waldo_TreeFelling_BushRadius", 4],
        ["Waldo_TreeFelling_ToolEfficiency", createHashMap],
        ["Waldo_TreeFelling_ProtectedAreas", []],
        ["Waldo_TreeFelling_Yields", []],
        ["Waldo_TreeFelling_RegrowSeconds", -1],
        // MISSION MAKER: server-validated breach targets and explosive effectiveness.
        ["Waldo_Breaching_Enable", false],
        ["Waldo_Breaching_Profiles", createHashMap],
        ["Waldo_Breaching_ExplosiveStrengths", createHashMapFromArray [
            ["DemoCharge_Remote_Ammo", 1], ["SatchelCharge_Remote_Ammo", 3]
        ]]
    ]]
]

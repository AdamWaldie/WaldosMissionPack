/*
 * Author: WaldoTheWarfighter
 * Defines hazardous-environment, tree-felling and explosive-breaching defaults. Zone/object
 * registration and damage/replacement execution remain in their locality-aware feature scripts.
 *
 * Schema: SHARED entries are [missionNamespace variable name, guarded default value].
 * Arguments: None. Return Value: HASHMAP consumed by Waldo_fnc_LoadFeatureConfigs.
 *
 * Example: add a named hazard preset HashMap or map a mod explosive ammo class to its strength.
 * Result: registered hazards or automatic breaching can use the added named content definition.
 * Current caller: Waldo_fnc_LoadFeatureConfigs from init.sqf using the SHARED scope.
 *
 * ACTIVATION MODEL: MIXED.
 * Hazard evaluation starts automatically when enabled, but danger exists only after a zone/emitter
 * is registered by script or ZEN. Tree felling and breaching install their handlers automatically
 * when enabled; breaching still needs a matching class/profile before an object is breachable.
 *
 * EDIT FOR A NORMAL MISSION: enable switches, hazard presets, allowed tools/content pools,
 * protected areas and breaching profiles/explosive strengths.
 * LEAVE ALONE UNLESS EXTENDING/TESTING: tick/cooldown/scheduler values and geometry tolerances.
 * CUSTOM CALLS: register pre-planned hazards from initServer.sqf with
 * Waldo_fnc_HazardRegisterZone/Emitter; runtime ZEN or
 * server triggers may add/remove them. Tree felling and breaching have no ZEN setup.
 *
 * CUSTOMISATION GUIDE:
 * MISSION MAKER - enable switches, named hazard presets, axe/tool class patterns, fallen-object
 * pools, protected areas/yields and breaching profiles/explosive strengths are mission content.
 * Hazard types are free stable IDs consumed by profiles (shipped examples HAZARD and NO_OXYGEN).
 * Each damage threshold is [exposure, damage fraction]; fatalExposure is seconds/exposure units.
 * Tree DirectionMode is RANDOM, STRIKE or ORIGINAL; RegrowSeconds -1 disables regrowth.
 * ADVANCED TUNING - hazard tick interval, exposure rate/decay, tree hit/cooldown/size geometry and
 * bush clearance affect scheduler cadence or world mutation. Test non-default values on the actual
 * terrain and use only existing classnames. Damage fractions must remain 0-1.
 *
 * HOW TO READ THE DATA BELOW:
 * Every `shared` row is `[variable name, guarded default]`, installed on all machines only when the
 * variable is still undefined. A Hazard preset is a HashMap with: `type` stable exposure bucket,
 * `label` player text, `rate` exposure gained per second, `decay` exposure lost per second outside,
 * `damageType` ACE/engine damage type, `damageThresholds` ascending `[exposure, damage fraction]`
 * stages, optional `fatalExposure`, optional `protectInVehicles`, optional `vehicleFactor`, and one
 * message per damage stage. `showStatus` controls the one continuously updated lower-left exposure
 * panel for that profile; it never consumes notification-card lanes. Optional `detectorItems`,
 * `detectorObjects`/`detectorObjectRange`, or advanced `awarenessCondition` settings restrict who
 * can see hazard information without preventing exposure or damage. When a detector requirement is
 * present it applies to the status panel and transition/damage notices by default; the two
 * `requireAwarenessFor*` booleans can override that policy.
 * A zone may override these keys without changing the reusable preset.
 *
 * Breaching profiles are keyed by target CfgVehicles class. A profile uses `radius` (metres),
 * `explosives` (required strength), `destroyOriginal`, `hideOriginal`, `deleteOriginal`, and
 * `replacements` (array of replacement definitions). ExplosiveStrengths maps CfgAmmo class to the
 * numeric strength contributed by one detonation. Empty profile maps deliberately make nothing
 * breachable until a mission supplies content.
 */
createHashMapFromArray [
    ["featureFamilies", ["Hazardous Environments", "Tree Felling", "Explosive Breaching"]],
    ["shared", [
        // MISSION MAKER master switch; ADVANCED cadence/presentation defaults.
        ["Waldo_Hazard_Enable", false],             // BOOL: run local exposure evaluation; creates no zones.
        ["Waldo_Hazard_Interval", 1],               // SECONDS: evaluation cadence; performance-sensitive.
        ["Waldo_Hazard_ShowStatus", true],          // BOOL: one continuous lower-left exposure panel; not a notification card.
        ["Waldo_Hazard_NotifyTransitions", true],   // BOOL: notify on entering/leaving a hazardous area.
        ["Waldo_Hazard_NotificationDuration", 6],   // SECONDS: transition-notification lifetime.
        // MISSION MAKER: reusable RP/gameplay profiles; zones may override individual keys.
        // BEGINNER: each preset below is `PRESET NAME` followed by its settings HashMap.
        // `rate` adds exposure each second; `decay` removes it after leaving. Each threshold row is
        // `[exposure needed, damage added]`. For example `[20, 0.01]` means 1% damage at exposure 20.
        ["Waldo_Hazard_Presets", createHashMapFromArray [ // preset ID -> complete/partial hazard profile schema above.
            ["MILD", createHashMapFromArray [
                ["type", "HAZARD"],             // internal exposure category; zones of this type share exposure.
                ["label", "Hazardous Area"],    // text shown to the player.
                ["rate", 0.5],                  // gain 0.5 exposure per second while inside.
                ["decay", 0.25],                // lose 0.25 exposure per second while safely outside.
                ["damageType", "stab"],         // ACE/engine damage type used when a threshold fires.
                ["damageThresholds", [
                    [20, 0.01],                   // at exposure 20, apply 1% damage per damage event.
                    [45, 0.02]                    // at exposure 45, apply 2% damage per damage event.
                ]],
                // OPTIONAL INFORMATION GATE EXAMPLES (uncomment and replace classnames if wanted):
                // ["detectorItems", ["ACE_microDAGR"]], // at least one listed carried/worn item.
                // ["detectorObjects", ["Land_Device_disassembled_F"]], // nearby detector object.
                // ["detectorObjectRange", 5], // metres from a detector object.
                // ["requireAwarenessForStatus", true], // hide live panel without detector/condition.
                // ["requireAwarenessForNotifications", true], // also hide entry/damage notices.
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
        ["Waldo_TreeFelling_Enable", false],        // BOOL: install felling handlers on interface clients/server.
        ["Waldo_TreeFelling_Range", 3],             // METRES: maximum usable tree/tool distance.
        ["Waldo_TreeFelling_BaseHits", 3],          // HITS: base strikes required before height adjustment.
        ["Waldo_TreeFelling_HeightFactor", 0.25],   // HITS PER METRE: extra resistance from tree height.
        ["Waldo_TreeFelling_HitCooldown", 0.7],     // SECONDS: minimum accepted time between strikes.
        ["Waldo_TreeFelling_WeaponPatterns", ["axe", "hatchet"]], // lower-case substrings matched in tool classnames.
        ["Waldo_TreeFelling_FallenClasses", ["Land_WoodenLog_F"]], // fallback CfgVehicles replacement pool.
        ["Waldo_TreeFelling_FallenClassesSmall", []],  // optional pool used below first SizeThreshold.
        ["Waldo_TreeFelling_FallenClassesMedium", []], // optional pool between SizeThresholds.
        ["Waldo_TreeFelling_FallenClassesLarge", []],  // optional pool above second SizeThreshold.
        ["Waldo_TreeFelling_SizeThresholds", [7, 15]], // METRES `[small/medium, medium/large]` boundaries.
        ["Waldo_TreeFelling_FallenRandomDirection", true], // compatibility BOOL; DirectionMode is authoritative.
        ["Waldo_TreeFelling_DirectionMode", "RANDOM"], // STRING: RANDOM, STRIKE (away from user) or ORIGINAL tree bearing.
        ["Waldo_TreeFelling_ClearBushes", false],   // BOOL: remove nearby bush terrain objects when felled.
        ["Waldo_TreeFelling_BushRadius", 4],        // METRES: bush-clearance radius.
        ["Waldo_TreeFelling_ToolEfficiency", createHashMap], // HashMap classname/pattern to positive hit multiplier.
        ["Waldo_TreeFelling_ProtectedAreas", []],   // ARRAY of inArea-compatible markers/triggers/locations/area arrays.
        ["Waldo_TreeFelling_Yields", []],           // ARRAY of `[CfgVehicles class, count]` objects spawned per tree.
        ["Waldo_TreeFelling_RegrowSeconds", -1],    // SECONDS: -1 never regrows; non-negative schedules regrowth.
        // MISSION MAKER: server-validated breach targets and explosive effectiveness.
        ["Waldo_Breaching_Enable", false],          // BOOL: install explosive detection; profiles still required.
        ["Waldo_Breaching_Profiles", createHashMap], // HashMap target classname -> profile described above.
        ["Waldo_Breaching_ExplosiveStrengths", createHashMapFromArray [ // CfgAmmo classname -> positive strength units.
            ["DemoCharge_Remote_Ammo", 1], ["SatchelCharge_Remote_Ammo", 3]
        ]]
    ]]
]

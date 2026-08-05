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
 * QUICK START - TREE FELLING:
 * 1. Change Waldo_TreeFelling_Enable to true.
 * 2. Check the classname of the axe supplied by your mod. It must contain one of the text fragments
 *    in Waldo_TreeFelling_WeaponPatterns. For example, `myMod_fireAxe` matches `"axe"`.
 * 3. Leave the remaining settings unchanged for the first test. Look at a tree within 3 metres,
 *    equip the axe and use the Fell Tree / Clear Brush action.
 * Arma 3 has no vanilla hand-held axe weapon, so enabling this feature without an axe mod or custom
 * weapon cannot create a usable cutting tool by itself.
 *
 * QUICK START - EXPLOSIVE BREACHING:
 * 1. Place an 8 m City Wall (`Land_City2_8m_F`) in Eden.
 * 2. Change Waldo_Breaching_Enable to true. The shipped profile below is already ready to use.
 * 3. In game, place and detonate an ACE M112 demolition block or satchel within 5 metres of it.
 * The example affects only that exact wall class. It does not make every wall in the mission
 * destructible. Copy the complete example profile and replace its target classname to add another.
 *
 * HOW TO READ A BREACH PROFILE:
 * The first quoted classname is the object that may be breached. Settings inside its HashMap are:
 * `radius` = how close the explosion must be; `explosives` = allowed CfgAmmo classnames;
 * `requiredStrength` = total force needed; `destroyOriginal` = damage the target;
 * `hideOriginal` = hide the target and its collision; `deleteOriginal` = permanently delete it;
 * `replacements` = optional objects spawned relative to the old target. Keep replacements empty for
 * a simple full-width opening. ExplosiveStrengths assigns force to each CfgAmmo class: the shipped
 * demo charge contributes 1 and the satchel contributes 3. Derived/scripted ammo subclasses inherit
 * the configured base-class strength. `deleteOriginal = false` is the safe default because a hidden
 * object can be restored with Waldo_fnc_BreachingReset; a deleted object cannot.
 *
 * SETTING-BY-SETTING GUIDE - HAZARDS:
 * - Waldo_Hazard_Enable (MISSION MAKER): starts local exposure checks; zones/emitters still require registration.
 * - Waldo_Hazard_Interval (ADVANCED): seconds between exposure updates; lower values increase client work.
 * - Waldo_Hazard_ShowStatus (MISSION MAKER): shows one continuously updated exposure panel rather than stacked cards.
 * - Waldo_Hazard_NotifyTransitions (MISSION MAKER): shows entry/exit messages when awareness rules permit them.
 * - Waldo_Hazard_NotificationDuration (MISSION MAKER): lifetime in seconds for transition messages.
 * - Waldo_Hazard_DosimeterEnable: installs exposure-reading interactions when hazards are enabled.
 * - Waldo_Hazard_DosimeterRequireItem: true requires one class from DosimeterItems to read exposure.
 * - Waldo_Hazard_DosimeterItems: carried/assigned item classnames accepted as a dosimeter.
 * - Waldo_Hazard_Treatments: rows of `[item classname, readable name, exposure reduction]`; [] disables treatment.
 * - Waldo_Hazard_TreatmentDuration: ACE progress duration in seconds before the item is consumed.
 * - Waldo_Hazard_TreatmentMedicOnly: true restricts treatment to units with Arma's Medic trait.
 * - Waldo_Hazard_Presets (MISSION MAKER): reusable named profile HashMaps; zones select one and may override fields.
 *
 * SETTING-BY-SETTING GUIDE - TREE FELLING:
 * - Waldo_TreeFelling_Enable: enables actions/handlers; it does not add an axe to player inventories.
 * - Waldo_TreeFelling_Range: maximum player-to-tree distance in metres.
 * - Waldo_TreeFelling_BaseHits: strikes required before height and tool multipliers are applied.
 * - Waldo_TreeFelling_HeightFactor: extra strikes per metre; 0.25 means one extra per four metres.
 * - Waldo_TreeFelling_HitCooldown: shortest accepted interval between strikes, in seconds.
 * - Waldo_TreeFelling_WeaponPatterns: case-insensitive weapon-class fragments accepted as tools.
 * - Waldo_TreeFelling_AllowedClasses: exact exceptional tree classes; [] uses normal model-name detection.
 * - Waldo_TreeFelling_FallenClasses: general valid CfgVehicles replacement pool.
 * - Waldo_TreeFelling_FallenClassesSmall: optional short-tree pool; [] falls back to the general pool.
 * - Waldo_TreeFelling_FallenClassesMedium: optional medium-tree pool; [] falls back to the general pool.
 * - Waldo_TreeFelling_FallenClassesLarge: optional tall-tree pool; [] falls back to the general pool.
 * - Waldo_TreeFelling_SizeThresholds: two increasing heights `[small end, medium end]` in metres.
 * - Waldo_TreeFelling_DirectionMode: RANDOM, STRIKE (away from user) or ORIGINAL tree bearing.
 * - Waldo_TreeFelling_ClearBushes: true also removes nearby bushes after an accepted action.
 * - Waldo_TreeFelling_BushRadius: bush-removal radius in metres.
 * - Waldo_TreeFelling_ToolEfficiency: fragment -> positive multiplier; exact or longest match wins.
 * - Waldo_TreeFelling_ProtectedAreas: marker/trigger/area entries in which felling is refused.
 * - Waldo_TreeFelling_Yields: `[CfgVehicles class, count]` reward rows spawned after felling.
 * - Waldo_TreeFelling_RegrowSeconds: positive delay restores the tree; -1 or 0 means never.
 *
 * SETTING-BY-SETTING GUIDE - BREACHING:
 * - Waldo_Breaching_Enable: starts ACE explosive detection; only explicitly profiled object classes react.
 * - Waldo_Breaching_Profiles: target CfgVehicles class -> complete profile described and demonstrated below.
 * - Waldo_Breaching_ShowNotifications: false keeps successful breaches mechanically silent. Set
 *   true only when the player who placed the charge should receive a WMP notification card.
 * - Waldo_Breaching_ExplosiveStrengths: CfgAmmo class -> positive force contributed by one detonation.
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
        ["Waldo_Hazard_DosimeterEnable", true],     // BOOL: install Read Exposure self/target interactions.
        ["Waldo_Hazard_DosimeterRequireItem", false], // false allows roleplay checks without a specific mod item.
        ["Waldo_Hazard_DosimeterItems", []],        // exact carried/assigned item classnames when requirement is true.
        ["Waldo_Hazard_Treatments", [               // each row: [consumed item classname, readable name, reduction].
            // ["armst_item_antirad", "Anti-radiation medication", 2]
        ]],
        ["Waldo_Hazard_TreatmentDuration", 4],      // SECONDS: completed ACE progress before consuming the item.
        ["Waldo_Hazard_TreatmentMedicOnly", false], // true requires the administering unit's Medic trait.
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
            ["RADIATION", createHashMapFromArray [
                ["type", "RADIATION"],             // separate accumulated exposure channel.
                ["label", "Radioactive Area"],
                ["rate", 1],
                ["decay", 0.001],
                ["damageType", "stab"],
                ["damageThresholds", [[1, 0.05], [4, 0.3], [5, 0.8]]],
                ["fatalExposure", 6],
                ["protectInVehicles", true],
                ["vehicleFactor", 0.01],
                ["protectIndoors", false],
                ["equipmentFactor", 0.01],
                ["protectiveItems", createHashMapFromArray [
                    ["headgear", []],               // add protective helmet classnames here.
                    ["goggles", []],                // add gas-mask/facewear classnames here.
                    ["hmd", []]                     // add protective NVG/HMD classnames here.
                ]],
                ["audioEnabled", true],             // radiation-only local Geiger/cough feedback.
                ["audioRequiresAwareness", false],  // true ties sound to detector/awareness rules.
                ["geigerLowSounds", ["Waldo_Hazard_GeigerLow1", "Waldo_Hazard_GeigerLow2", "Waldo_Hazard_GeigerLow3", "Waldo_Hazard_GeigerLow4"]],
                ["geigerHighSounds", ["Waldo_Hazard_Geiger1", "Waldo_Hazard_Geiger2", "Waldo_Hazard_Geiger3", "Waldo_Hazard_Geiger4"]],
                ["geigerHighIntensity", 0.5],       // intensity 0-1 where the high sound pool begins.
                ["geigerMinimumInterval", 0.45],    // fastest seconds between clicks near maximum intensity.
                ["geigerMaximumInterval", 2.5],    // slowest seconds between clicks near zone edge.
                ["coughEnabled", true],
                ["coughSounds", ["Waldo_Hazard_Cough1", "Waldo_Hazard_Cough2", "Waldo_Hazard_Cough3"]],
                ["coughCooldown", 12],              // minimum seconds between injury coughs.
                ["damageStageMessages", ["Radiation exposure is causing injury.", "Radiation sickness is becoming severe.", "Critical radiation dose: evacuate immediately."]]
            ]],
            ["VACUUM", createHashMapFromArray [
                ["type", "NO_OXYGEN"], ["label", "Unpressurised Area"], ["rate", 8], ["decay", 2],
                ["protectInVehicles", true], ["vehicleFactor", 0], ["damageType", "stab"],
                ["damageThresholds", [[8, 0.04], [20, 0.12]]], ["fatalExposure", 35],
                ["damageStageMessages", ["Oxygen deprivation is causing injury.", "Critical oxygen deprivation: reach pressure immediately."]]
            ]]
        ]],
        // TREE FELLING - START HERE. Change only false to true for your first test.
        ["Waldo_TreeFelling_Enable", false],        // false = off; true = players can use configured axe weapons.
        ["Waldo_TreeFelling_Range", 3],             // Player must be this many metres or closer to the tree.
        ["Waldo_TreeFelling_BaseHits", 3],          // Every tree needs at least this many accepted strikes.
        ["Waldo_TreeFelling_HeightFactor", 0.25],   // Taller trees need 1 extra strike per 4 metres of height.
        ["Waldo_TreeFelling_HitCooldown", 0.7],     // Ignore strikes made less than 0.7 seconds apart.

        // A weapon is accepted when its classname contains either word below, ignoring capitals.
        // Example: `myMod_fireAxe` matches "axe". Add a new quoted fragment for another axe mod.
        ["Waldo_TreeFelling_WeaponPatterns", ["axe", "hatchet"]],

        // Normally leave this empty. Add an exact tree object classname only when a mod tree's model
        // name does not contain the word "tree": ["MyMod_OldOak_F", "MyMod_Pine_F"].
        ["Waldo_TreeFelling_AllowedClasses", []],

        // The original tree is hidden and one object from the applicable list is placed in its place.
        ["Waldo_TreeFelling_FallenClasses", ["Land_WoodenLog_F"]], // Used when a size list below is empty.
        ["Waldo_TreeFelling_FallenClassesSmall", []],  // Trees shorter than 7 m; [] uses FallenClasses.
        ["Waldo_TreeFelling_FallenClassesMedium", []], // Trees from 7 m through 15 m; [] uses FallenClasses.
        ["Waldo_TreeFelling_FallenClassesLarge", []],  // Trees taller than 15 m; [] uses FallenClasses.
        ["Waldo_TreeFelling_SizeThresholds", [7, 15]], // First number ends small; second ends medium.
        ["Waldo_TreeFelling_DirectionMode", "RANDOM"], // RANDOM, STRIKE (away from player), or ORIGINAL.
        ["Waldo_TreeFelling_ClearBushes", false],   // true also clears bushes near a successful strike.
        ["Waldo_TreeFelling_BushRadius", 4],        // Bush clearing distance in metres; ignored when false above.

        // Optional cutting-speed multipliers. The longest matching classname fragment wins.
        // 1 = normal, 2 = twice as effective, 0.5 = half as effective.
        ["Waldo_TreeFelling_ToolEfficiency", createHashMapFromArray [
            ["axe", 1],
            ["hatchet", 1]
        ]],

        // Optional no-felling areas. Use existing Eden marker names: ["base_no_logging", "town_safe_zone"].
        ["Waldo_TreeFelling_ProtectedAreas", []],
        // Optional reward objects per felled tree. Example: [["Land_WoodenLog_F", 2]].
        ["Waldo_TreeFelling_Yields", []],
        ["Waldo_TreeFelling_RegrowSeconds", -1],    // -1 or 0 = never; a positive number regrows after that many seconds.

        // EXPLOSIVE BREACHING - START HERE. The example wall is safe but inactive until this is true.
        ["Waldo_Breaching_Enable", false],
        ["Waldo_Breaching_ShowNotifications", false], // BOOL: opt in to a WMP UI card for the player who placed a successful charge. Default breaches are silent.
        ["Waldo_Breaching_Profiles", createHashMapFromArray [
            // TARGET OBJECT CLASSNAME: this exact vanilla 8 m wall becomes breachable.
            ["Land_City2_8m_F", createHashMapFromArray [
                ["radius", 5], // Explosion must be within 5 metres of the wall.
                ["explosives", ["DemoCharge_Remote_Ammo", "SatchelCharge_Remote_Ammo"]],
                ["requiredStrength", 1], // One demo charge (1) or one satchel (3) is enough.
                ["destroyOriginal", true], // Damage the original wall when the threshold is reached.
                ["hideOriginal", true],    // Hide it to guarantee a clear full-width opening.
                ["deleteOriginal", false], // Keep it recoverable with Waldo_fnc_BreachingReset.
                ["replacements", []]       // [] = create no debris or replacement wall sections.
            ]]
            // To add another target, place a comma above and copy the entire target/profile block.
        ]],
        ["Waldo_Breaching_ExplosiveStrengths", createHashMapFromArray [
            // CfgAmmo classname, force contributed by one detonation.
            ["DemoCharge_Remote_Ammo", 1],
            ["SatchelCharge_Remote_Ammo", 3]
        ]]
    ]]
]

/*
 * Author: WaldoTheWarfighter
 * Defines airborne gunship, dynamic paradrop and Dynamic AA defaults. Shared airframe/chute pools
 * remain independent of operational side; shared AA pools feed curator selectors and server
 * validation, while server-only safety limits and jump envelopes remain authoritative.
 *
 * Schema: SHARED entries are [name, default]; SERVER entries are [name, default, publish BOOL].
 * ALIASES entries are [scope, target name, source name] and copy only when target is undefined.
 * Arguments: None.
 * Return Value: HASHMAP consumed by Waldo_fnc_LoadFeatureConfigs.
 *
 * Example: extend Waldo_Paradrop_AircraftClasses with compatible mod aircraft before activation.
 * Result: later scripted or ZEN paradrop creation may offer those validated aircraft classes.
 * Current callers: init.sqf (SHARED) and initServer.sqf (SERVER) through the loader.
 *
 * ACTIVATION MODEL: CALL-DRIVEN / ZEN-CREATED.
 * This file does not create a gunship, drop zone or AA system. It supplies allowed aircraft,
 * parachutes, boarding objects, AA asset pools and safety bounds to later creation calls/modules.
 * Waldo_Gunship_Enable permits gunship registration but still does not instantiate one by itself.
 *
 * EDIT FOR A NORMAL MISSION: content pools, feature availability and jump envelopes for the loaded
 * mod set. LEAVE ALONE UNLESS EXTENDING/TESTING: monitor cadence, service thresholds and server
 * maximum bounds. CUSTOM CALLS: put pre-planned Waldo_fnc_GunshipRegister,
 * Waldo_fnc_ParadropCreateDropZone or Waldo_fnc_DynamicAACreate calls in initServer.sqf. Use a
 * server-owned trigger/script for later creation, or the matching ZEN module during play.
 *
 * CUSTOMISATION GUIDE:
 * MISSION MAKER - feature enablement, gunship aircraft pools, paradrop aircraft/chutes/boarding
 * objects, Dynamic AA side/faction pools and jump-envelope classes are intended mission content.
 * Pool keys are WEST, EAST, INDEPENDENT and CIVILIAN; faction maps override selected side pools.
 * Dynamic AA pool keys are radarClasses, staticSitePools, mobileClasses and fighterClasses.
 * ADVANCED TUNING - gunship monitor/service thresholds and Dynamic AA maximum bounds protect the
 * system from invalid or excessive runtime requests. Altitudes/radii are metres, intervals and
 * service duration are seconds, fuel/ammo/damage values are fractions 0-1, and -1 service cycles
 * means unlimited. Static-line speed is kilometres/hour as reported by Arma's speed command.
 *
 * HOW TO READ THE DATA BELOW:
 * `shared` rows are `[variable, default]` on every machine. `server` rows are
 * `[variable, default, publish]`; publish true synchronises the server value to clients/JIP, while
 * false keeps an authority/safety bound server-only. Pool HashMaps use visible side or faction keys,
 * then arrays of actual CfgVehicles/CfgWeapons classnames. Editing a pool changes selector content;
 * it creates nothing until the documented creation call or ZEN module runs.
 * SideAircraftPools maps a SIDE name to candidate gunship classes. FactionAircraftPools maps a
 * CfgFactionClasses key to a narrower candidate list; vehicle selection is deliberately independent
 * of the operational side. Dynamic-AA side/faction entries are HashMaps containing `radarClasses`,
 * `staticSitePools` (each nested array is one complete radar/weapon site), `mobileClasses`, and
 * `fighterClasses`. Empty arrays disable that response type without disabling the whole system.
 *
 * SETTING-BY-SETTING GUIDE - GUNSHIP:
 * - Waldo_Gunship_Enable (MISSION MAKER): permits registration and ZEN creation; it spawns nothing by itself.
 * - Waldo_Gunship_DefaultAltitude (MISSION MAKER): starting orbit altitude used when a call/module does not override it.
 * - Waldo_Gunship_MaximumAltitude (ADVANCED): server rejection ceiling for requested orbit altitudes.
 * - Waldo_Gunship_DefaultRadius (MISSION MAKER): starting orbit radius when no request-specific value is supplied.
 * - Waldo_Gunship_MaximumRadius (ADVANCED): server rejection ceiling for requested orbit radii.
 * - Waldo_Gunship_DefaultServiceDuration (MISSION MAKER): seconds a sortie remains available before RTB/service.
 * - Waldo_Gunship_MonitorInterval (ADVANCED): seconds between server state checks; lower values cost more CPU.
 * - Waldo_Gunship_MinimumFuel (MISSION MAKER): fraction 0-1 that causes RTB when fuel falls to/below it.
 * - Waldo_Gunship_MaximumDamage (MISSION MAKER): fraction 0-1 that causes RTB when damage reaches/exceeds it.
 * - Waldo_Gunship_ServiceFuelFraction (MISSION MAKER): fuel fraction after a completed service cycle.
 * - Waldo_Gunship_ServiceAmmoFraction (MISSION MAKER): ammunition fraction after service.
 * - Waldo_Gunship_ServiceDamage (MISSION MAKER): remaining damage after service; 0 means fully repaired.
 * - Waldo_Gunship_MaximumServiceCycles (MISSION MAKER): -1 unlimited, 0 no return sortie, or a positive limit.
 * - Waldo_Gunship_ReturnWhenOutOfAmmo (MISSION MAKER): true orders RTB when no usable weapon ammunition remains.
 * - Waldo_Gunship_SideAircraftPools (MISSION MAKER): side fallback -> valid aircraft classes; selection side is separate.
 * - Waldo_Gunship_FactionAircraftPools (OPTIONAL): faction-specific narrower pools; leave empty for side-pool selection.
 *
 * SETTING-BY-SETTING GUIDE - PARADROP:
 * - Waldo_Paradrop_AircraftClasses (MISSION MAKER): transport aircraft offered by scripts and ZEN selectors.
 * - Waldo_Paradrop_StaticChuteClasses (MISSION MAKER): vehicle parachute classes usable for static-line jumps.
 * - Waldo_Paradrop_HaloBackpackClasses (MISSION MAKER): backpack classes that provide steerable HALO parachutes.
 * - Waldo_Paradrop_BoardingPointClasses (MISSION MAKER): movable objects offered as labelled boarding points.
 * - WALDO_STATIC_MINALTITUDE (MISSION MAKER): lowest permitted static-line drop altitude in metres.
 * - WALDO_STATIC_MAXALTITUDE (MISSION MAKER): highest permitted static-line drop altitude; must exceed the minimum.
 * - WALDO_STATIC_MAXSPEED (MISSION MAKER): fastest permitted static-line release speed in kilometres per hour.
 * - WALDO_STATIC_STATICCHUTE (MISSION MAKER): preferred static-line chute class; WMP falls back if it is unavailable.
 * - WALDO_PARA_HALOALTITUDE (MISSION MAKER): default HALO release altitude in metres.
 * - WALDO_PARA_HALOCHUTE (MISSION MAKER): default steerable parachute backpack class.
 *
 * SETTING-BY-SETTING GUIDE - DYNAMIC AA:
 * - Waldo_DynamicAA_SideAssetPools (MISSION MAKER): fallback AA content by operational side.
 * - Waldo_DynamicAA_FactionAssetPools (MISSION MAKER): optional content by faction, independent from operational side.
 * - Waldo_DynamicAA_DefaultDetectionInterval (ADVANCED): seconds between server target scans.
 * - Waldo_DynamicAA_MaximumRadius (ADVANCED): largest detection/engagement radius the server accepts.
 * - Waldo_DynamicAA_MaximumAltitude (ADVANCED): largest altitude ceiling the server accepts.
 * - Waldo_DynamicAA_MaximumFighters (ADVANCED): maximum fighters one AA system may scramble.
 *
 * POOL EXAMPLE:
 * `["MY_FACTION", createHashMapFromArray [["radarClasses", ["My_Radar_F"]],
 * ["staticSitePools", [["My_Radar_F", "My_SAM_F"]]], ["mobileClasses", ["My_AA_F"]],
 * ["fighterClasses", ["My_Fighter_F"]]]]]` defines selectable content only. A script/ZEN request
 * still chooses operational side, quantities, position, radii and interaction policy.
 */
createHashMapFromArray [
    ["featureFamilies", ["Airborne Gunship", "Dynamic Paradrop", "Dynamic Anti-Air"]],
    ["shared", [
        // MISSION MAKER: gunship availability, service rules and independent aircraft content pools.
        ["Waldo_Gunship_Enable", true],             // BOOL: permits registration/use; creates no aircraft itself.
        ["Waldo_Gunship_DefaultAltitude", 700],      // METRES ASL/ATL as selected by the gunship controller.
        ["Waldo_Gunship_MaximumAltitude", 5000],     // METRES: validation ceiling for scripted/ZEN requests.
        ["Waldo_Gunship_DefaultRadius", 1500],       // METRES: default orbit radius around the target area.
        ["Waldo_Gunship_MaximumRadius", 10000],      // METRES: largest accepted orbit radius.
        ["Waldo_Gunship_DefaultServiceDuration", 900], // SECONDS: available service time per sortie.
        ["Waldo_Gunship_MonitorInterval", 2],         // ADVANCED: seconds between state checks.
        ["Waldo_Gunship_MinimumFuel", 0.25],         // FRACTION 0-1: RTB/service threshold.
        ["Waldo_Gunship_MaximumDamage", 0.65],       // FRACTION 0-1: RTB/service threshold.
        ["Waldo_Gunship_ServiceFuelFraction", 1],    // FRACTION 0-1: fuel after service.
        ["Waldo_Gunship_ServiceAmmoFraction", 1],    // FRACTION 0-1: ammunition after service.
        ["Waldo_Gunship_ServiceDamage", 0],          // FRACTION 0-1: remaining damage after service.
        ["Waldo_Gunship_MaximumServiceCycles", -1],  // -1 unlimited; otherwise zero or a positive count.
        ["Waldo_Gunship_ReturnWhenOutOfAmmo", true], // BOOL: RTB automatically when usable weapons are empty.
        ["Waldo_Gunship_SideAircraftPools", createHashMapFromArray [ // SIDE ID -> candidate CfgVehicles classes.
            ["WEST", ["B_T_VTOL_01_armed_F"]], ["EAST", []], ["INDEPENDENT", []], ["CIVILIAN", []]
        ]],
        // OPTIONAL: normally leave empty. Add `CfgFactionClasses name -> aircraft classname ARRAY`
        // rows only when a named faction must use a narrower pool than the side pool above.
        ["Waldo_Gunship_FactionAircraftPools", createHashMap],
        // MISSION MAKER: classnames shown by paradrop and boarding selectors.
        ["Waldo_Paradrop_AircraftClasses", [ // transport-capable CfgVehicles classes offered to scripts/ZEN.
            "B_T_VTOL_01_infantry_F", "O_T_VTOL_02_infantry_dynamicLoadout_F",
            "B_Heli_Transport_03_unarmed_F", "O_Heli_Transport_04_covered_F", "I_Heli_Transport_02_F"
        ]],
        ["Waldo_Paradrop_StaticChuteClasses", ["NonSteerable_Parachute_F"]], // ARRAY: vehicle chute classes for scripted static line.
        ["Waldo_Paradrop_HaloBackpackClasses", ["B_Parachute", "O_Parachute", "I_Parachute"]], // ARRAY: steerable chute backpack classes.
        ["Waldo_Paradrop_BoardingPointClasses", [ // movable CfgVehicles objects offered by the boarding-point module.
            "FlagPole_F", "Land_InfoStand_V1_F", "Land_InfoStand_V2_F", "Land_MapBoard_F",
            "Land_Laptop_unfolded_F", "Land_CampingTable_small_F", "Land_PortableLight_single_F"
        ]],
        // MISSION MAKER: read on both the curator client (friendly selectors) and server (validated spawning).
        // The pool key is only a content profile; it never changes the operational side selected in ZEN.
        ["Waldo_DynamicAA_SideAssetPools", createHashMapFromArray [ // SIDE ID -> fallback AA content HashMap.
            ["WEST", createHashMapFromArray [
                ["radarClasses", ["B_Radar_System_01_F", "Land_Radar_F"]],
                ["staticSitePools", [["B_Radar_System_01_F", "B_SAM_System_01_F", "B_AAA_System_01_F"]]],
                ["mobileClasses", ["B_APC_Tracked_01_AA_F"]],
                ["fighterClasses", ["B_Plane_Fighter_01_F", "B_Plane_Fighter_01_Stealth_F"]]
            ]],
            ["EAST", createHashMapFromArray [
                ["radarClasses", ["O_Radar_System_02_F", "Land_Radar_F"]],
                ["staticSitePools", [["O_Radar_System_02_F", "O_SAM_System_04_F", "B_AAA_System_01_F"]]],
                ["mobileClasses", ["O_APC_Tracked_02_AA_F", "O_T_APC_Tracked_02_AA_ghex_F"]],
                ["fighterClasses", ["O_Plane_Fighter_02_F", "O_Plane_Fighter_02_Stealth_F"]]
            ]],
            ["INDEPENDENT", createHashMapFromArray [
                ["radarClasses", ["I_E_Radar_System_01_F", "Land_Radar_F"]],
                ["staticSitePools", [["I_E_Radar_System_01_F", "I_E_SAM_System_03_F", "B_AAA_System_01_F"]]],
                ["mobileClasses", ["I_LT_01_AA_F"]],
                ["fighterClasses", ["I_Plane_Fighter_03_dynamicLoadout_F"]]
            ]]
        ]],
        ["Waldo_DynamicAA_FactionAssetPools", createHashMapFromArray [ // optional content profiles, independent of operational side.
            ["BLU_F", createHashMapFromArray [
                ["radarClasses", ["B_Radar_System_01_F", "Land_Radar_F"]],
                ["staticSitePools", [["B_Radar_System_01_F", "B_SAM_System_01_F", "B_AAA_System_01_F"]]],
                ["mobileClasses", ["B_APC_Tracked_01_AA_F"]],
                ["fighterClasses", ["B_Plane_Fighter_01_F", "B_Plane_Fighter_01_Stealth_F"]]
            ]],
            ["OPF_F", createHashMapFromArray [
                ["radarClasses", ["O_Radar_System_02_F", "Land_Radar_F"]],
                ["staticSitePools", [["O_Radar_System_02_F", "O_SAM_System_04_F", "B_AAA_System_01_F"]]],
                ["mobileClasses", ["O_APC_Tracked_02_AA_F", "O_T_APC_Tracked_02_AA_ghex_F"]],
                ["fighterClasses", ["O_Plane_Fighter_02_F", "O_Plane_Fighter_02_Stealth_F"]]
            ]],
            ["IND_F", createHashMapFromArray [
                ["radarClasses", ["I_E_Radar_System_01_F", "Land_Radar_F"]],
                ["staticSitePools", [["I_E_Radar_System_01_F", "I_E_SAM_System_03_F", "B_AAA_System_01_F"]]],
                ["mobileClasses", ["I_LT_01_AA_F"]],
                ["fighterClasses", ["I_Plane_Fighter_03_dynamicLoadout_F"]]
            ]]
        ]]
    ]],
    ["server", [
        // ADVANCED safety bounds for server-created Dynamic AA systems.
        ["Waldo_DynamicAA_DefaultDetectionInterval", 1, false], // SECONDS: server detection cadence.
        ["Waldo_DynamicAA_MaximumRadius", 50000, false], // METRES: accepted detection/engagement radius ceiling.
        ["Waldo_DynamicAA_MaximumAltitude", 10000, false], // METRES: accepted altitude ceiling.
        ["Waldo_DynamicAA_MaximumFighters", 12, false], // COUNT: maximum fighters one system may scramble.
        // MISSION MAKER: valid jump envelopes and default parachute classes.
        ["WALDO_STATIC_MINALTITUDE", 180, true], // METRES: lowest accepted static-line drop altitude.
        ["WALDO_STATIC_MAXALTITUDE", 350, true], // METRES: highest accepted static-line drop altitude.
        ["WALDO_STATIC_MAXSPEED", 310, true], // KM/H: maximum aircraft speed for static-line release.
        ["WALDO_STATIC_STATICCHUTE", "rhs_d6_Parachute", true], // CLASSNAME: default static-line chute; runtime fallback applies if absent.
        ["WALDO_PARA_HALOALTITUDE", 1000, true], // METRES: default freefall/HALO drop altitude.
        ["WALDO_PARA_HALOCHUTE", "B_Parachute", true] // CLASSNAME: default steerable parachute backpack.
    ]],
    // COMPATIBILITY: old combined chute pool follows the new static-line pool when undefined.
    ["aliases", [["SHARED", "Waldo_Paradrop_ChuteClasses", "Waldo_Paradrop_StaticChuteClasses"]]]
]

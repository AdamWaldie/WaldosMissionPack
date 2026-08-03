/*
 * Author: WaldoTheWarfighter
 * Defines airborne gunship, dynamic paradrop and Dynamic AA defaults. Shared airframe/chute pools
 * remain independent of operational side; server-only AA pools and jump limits are JIP-published.
 *
 * Schema: SHARED entries are [name, default]; SERVER entries are [name, default, publish BOOL].
 * ALIASES entries are [scope, target name, source name] and copy only when target is undefined.
 * Arguments: None.
 * Return Value: HASHMAP consumed by Waldo_fnc_LoadFeatureConfigs.
 *
 * Example: extend Waldo_Paradrop_AircraftClasses with compatible mod aircraft before activation.
 * Current callers: init.sqf (SHARED) and initServer.sqf (SERVER) through the loader.
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
 */
createHashMapFromArray [
    ["featureFamilies", ["Airborne Gunship", "Dynamic Paradrop", "Dynamic Anti-Air"]],
    ["shared", [
        // MISSION MAKER: gunship availability, service rules and independent aircraft content pools.
        ["Waldo_Gunship_Enable", false],
        ["Waldo_Gunship_DefaultAltitude", 700],
        ["Waldo_Gunship_MaximumAltitude", 5000],
        ["Waldo_Gunship_DefaultRadius", 1500],
        ["Waldo_Gunship_MaximumRadius", 10000],
        ["Waldo_Gunship_DefaultServiceDuration", 900],
        ["Waldo_Gunship_MonitorInterval", 2],         // ADVANCED: seconds between state checks.
        ["Waldo_Gunship_MinimumFuel", 0.25],
        ["Waldo_Gunship_MaximumDamage", 0.65],
        ["Waldo_Gunship_ServiceFuelFraction", 1],
        ["Waldo_Gunship_ServiceAmmoFraction", 1],
        ["Waldo_Gunship_ServiceDamage", 0],
        ["Waldo_Gunship_MaximumServiceCycles", -1],  // -1 unlimited; otherwise zero or a positive count.
        ["Waldo_Gunship_ReturnWhenOutOfAmmo", true],
        ["Waldo_Gunship_SideAircraftPools", createHashMapFromArray [
            ["WEST", ["B_T_VTOL_01_armed_F"]], ["EAST", []], ["INDEPENDENT", []], ["CIVILIAN", []]
        ]],
        ["Waldo_Gunship_FactionAircraftPools", createHashMap],
        // MISSION MAKER: classnames shown by paradrop and boarding selectors.
        ["Waldo_Paradrop_AircraftClasses", [
            "B_T_VTOL_01_infantry_F", "O_T_VTOL_02_infantry_dynamicLoadout_F",
            "B_Heli_Transport_03_unarmed_F", "O_Heli_Transport_04_covered_F", "I_Heli_Transport_02_F"
        ]],
        ["Waldo_Paradrop_StaticChuteClasses", ["NonSteerable_Parachute_F"]],
        ["Waldo_Paradrop_HaloBackpackClasses", ["B_Parachute", "O_Parachute", "I_Parachute"]],
        ["Waldo_Paradrop_BoardingPointClasses", [
            "FlagPole_F", "Land_InfoStand_V1_F", "Land_InfoStand_V2_F", "Land_MapBoard_F",
            "Land_Laptop_unfolded_F", "Land_CampingTable_small_F", "Land_PortableLight_single_F"
        ]]
    ]],
    ["server", [
        // ADVANCED safety bounds for server-created Dynamic AA systems.
        ["Waldo_DynamicAA_DefaultDetectionInterval", 1, false],
        ["Waldo_DynamicAA_MaximumRadius", 50000, false],
        ["Waldo_DynamicAA_MaximumAltitude", 10000, false],
        ["Waldo_DynamicAA_MaximumFighters", 12, false],
        // MISSION MAKER: JIP-published candidate assets; class availability is validated at runtime.
        ["Waldo_DynamicAA_SideAssetPools", createHashMapFromArray [
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
        ], true],
        ["Waldo_DynamicAA_FactionAssetPools", createHashMap, true],
        // MISSION MAKER: valid jump envelopes and default parachute classes.
        ["WALDO_STATIC_MINALTITUDE", 180, true],
        ["WALDO_STATIC_MAXALTITUDE", 350, true],
        ["WALDO_STATIC_MAXSPEED", 310, true],
        ["WALDO_STATIC_STATICCHUTE", "rhs_d6_Parachute", true],
        ["WALDO_PARA_HALOALTITUDE", 1000, true],
        ["WALDO_PARA_HALOCHUTE", "B_Parachute", true]
    ]],
    // COMPATIBILITY: old combined chute pool follows the new static-line pool when undefined.
    ["aliases", [["SHARED", "Waldo_Paradrop_ChuteClasses", "Waldo_Paradrop_StaticChuteClasses"]]]
]

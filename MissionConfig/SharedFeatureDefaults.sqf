/*
 * Author: WaldoTheWarfighter
 * Defines repeat-safe feature defaults required on every machine. This file contains configuration
 * only: it does not start systems, publish authoritative state or wait for another locality.
 * Existing missionNamespace values always win so server broadcasts and pre-init overrides survive.
 *
 * Arguments: None.
 * Return Value: Nothing; guarded shared defaults are installed in missionNamespace.
 *
 * Example: call compile preprocessFileLineNumbers "MissionConfig\SharedFeatureDefaults.sqf";
 * Current caller: init.sqf, before shared readiness and feature activation.
 */
if (isNil "Waldo_UI_Theme") then {Waldo_UI_Theme = "DEFAULT"};
if (isNil "Waldo_UI_CustomThemes") then {Waldo_UI_CustomThemes = createHashMap};
if (isNil "Waldo_UI_ThemeOverrides") then {Waldo_UI_ThemeOverrides = createHashMap};

if (isNil "Waldo_Persistence_Enable") then {Waldo_Persistence_Enable = false};
if (isNil "Waldo_Persistence_PlayerSaveInterval") then {Waldo_Persistence_PlayerSaveInterval = 60};
if (isNil "Waldo_Persistence_ObjectSaveInterval") then {Waldo_Persistence_ObjectSaveInterval = 60};
if (isNil "Waldo_Persistence_SaveLoadout") then {Waldo_Persistence_SaveLoadout = true};
if (isNil "Waldo_Persistence_SaveMedical") then {Waldo_Persistence_SaveMedical = true};
if (isNil "Waldo_Persistence_SaveFoodWater") then {Waldo_Persistence_SaveFoodWater = false};
if (isNil "Waldo_Persistence_SavePosition") then {Waldo_Persistence_SavePosition = false};
if (isNil "Waldo_Persistence_SaveRadios") then {Waldo_Persistence_SaveRadios = false};
if (isNil "Waldo_Persistence_DatabaseName") then {Waldo_Persistence_DatabaseName = "WaldosMissionPack"};
if (isNil "Waldo_Persistence_DefaultCustomVariables") then {
    Waldo_Persistence_DefaultCustomVariables = [
        "Waldo_ObjectScale", "Waldo_ObjectScaleOriginal",
        "Waldo_Breaching_Processed", "Waldo_Breaching_AccumulatedStrength",
        "Waldo_FieldResupply_Hub", "Waldo_FieldResupply_Stock",
        "Waldo_FieldResupply_Deployed", "Waldo_FieldResupply_Charges"
    ];
};

if (isNil "Waldo_FieldResupply_Enable") then {Waldo_FieldResupply_Enable = false};
if (isNil "Waldo_FieldResupply_CrateClass") then {Waldo_FieldResupply_CrateClass = "Box_NATO_Ammo_F"};
if (isNil "Waldo_FieldResupply_DefaultCarrierCapacity") then {Waldo_FieldResupply_DefaultCarrierCapacity = 2};
if (isNil "Waldo_FieldResupply_ChargesPerCrate") then {Waldo_FieldResupply_ChargesPerCrate = 5};
if (isNil "Waldo_FieldResupply_MagazinesPerType") then {Waldo_FieldResupply_MagazinesPerType = 1};
if (isNil "Waldo_FieldResupply_UseCapacityBasedAmounts") then {Waldo_FieldResupply_UseCapacityBasedAmounts = true};
if (isNil "Waldo_FieldResupply_CapacityAmounts") then {Waldo_FieldResupply_CapacityAmounts = [4, 3, 8, 3, 2]};
if (isNil "Waldo_FieldResupply_MinimumMagazineRounds") then {Waldo_FieldResupply_MinimumMagazineRounds = 2};
if (isNil "Waldo_FieldResupply_AllowedMagazines") then {Waldo_FieldResupply_AllowedMagazines = []};
if (isNil "Waldo_FieldResupply_BlockedMagazines") then {Waldo_FieldResupply_BlockedMagazines = []};
if (isNil "Waldo_FieldResupply_RetainOnRespawn") then {Waldo_FieldResupply_RetainOnRespawn = true};

if (isNil "Waldo_Rally_Enable") then {Waldo_Rally_Enable = false};
if (isNil "Waldo_Rally_ObjectClass") then {Waldo_Rally_ObjectClass = "Land_SatelliteAntenna_01_F"};
if (isNil "Waldo_Rally_Duration") then {Waldo_Rally_Duration = 180};
if (isNil "Waldo_Rally_DeploymentTime") then {Waldo_Rally_DeploymentTime = 15};
if (isNil "Waldo_Rally_Cooldown") then {Waldo_Rally_Cooldown = 300};
if (isNil "Waldo_Rally_EnemyExclusionRadius") then {Waldo_Rally_EnemyExclusionRadius = 100};
if (isNil "Waldo_Rally_MinimumGroupMembers") then {Waldo_Rally_MinimumGroupMembers = 2};
if (isNil "Waldo_Rally_PlacementDistance") then {Waldo_Rally_PlacementDistance = 2};
if (isNil "Waldo_Rally_MaximumSlope") then {Waldo_Rally_MaximumSlope = 20};
if (isNil "Waldo_Rally_RespawnClearance") then {Waldo_Rally_RespawnClearance = 2.5};
if (isNil "Waldo_Rally_RespawnSearchDistance") then {Waldo_Rally_RespawnSearchDistance = 15};
if (isNil "Waldo_Rally_AllowRegroup") then {Waldo_Rally_AllowRegroup = false};

if (isNil "Waldo_Recovery_ScanInterval") then {Waldo_Recovery_ScanInterval = 3};
if (isNil "Waldo_Recovery_NotificationRadius") then {Waldo_Recovery_NotificationRadius = 100};
if (isNil "Waldo_Recovery_CreateWorkshopMarkers") then {Waldo_Recovery_CreateWorkshopMarkers = true};
if (isNil "Waldo_Recovery_PlacementClearance") then {Waldo_Recovery_PlacementClearance = 3};
if (isNil "Waldo_Recovery_DefaultCustomVariables") then {Waldo_Recovery_DefaultCustomVariables = []};
if (isNil "Waldo_Recovery_PackageClasses") then {Waldo_Recovery_PackageClasses = ["B_Slingload_01_Cargo_F", "Land_Pallet_MilBoxes_F"]};

if (isNil "Waldo_Gunship_Enable") then {Waldo_Gunship_Enable = false};
if (isNil "Waldo_Gunship_DefaultAltitude") then {Waldo_Gunship_DefaultAltitude = 700};
if (isNil "Waldo_Gunship_MaximumAltitude") then {Waldo_Gunship_MaximumAltitude = 5000};
if (isNil "Waldo_Gunship_DefaultRadius") then {Waldo_Gunship_DefaultRadius = 1500};
if (isNil "Waldo_Gunship_MaximumRadius") then {Waldo_Gunship_MaximumRadius = 10000};
if (isNil "Waldo_Gunship_DefaultServiceDuration") then {Waldo_Gunship_DefaultServiceDuration = 900};
if (isNil "Waldo_Gunship_MonitorInterval") then {Waldo_Gunship_MonitorInterval = 2};
if (isNil "Waldo_Gunship_MinimumFuel") then {Waldo_Gunship_MinimumFuel = 0.25};
if (isNil "Waldo_Gunship_MaximumDamage") then {Waldo_Gunship_MaximumDamage = 0.65};
if (isNil "Waldo_Gunship_ServiceFuelFraction") then {Waldo_Gunship_ServiceFuelFraction = 1};
if (isNil "Waldo_Gunship_ServiceAmmoFraction") then {Waldo_Gunship_ServiceAmmoFraction = 1};
if (isNil "Waldo_Gunship_ServiceDamage") then {Waldo_Gunship_ServiceDamage = 0};
if (isNil "Waldo_Gunship_MaximumServiceCycles") then {Waldo_Gunship_MaximumServiceCycles = -1};
if (isNil "Waldo_Gunship_ReturnWhenOutOfAmmo") then {Waldo_Gunship_ReturnWhenOutOfAmmo = true};
if (isNil "Waldo_Gunship_SideAircraftPools") then {
    Waldo_Gunship_SideAircraftPools = createHashMapFromArray [
        ["WEST", ["B_T_VTOL_01_armed_F"]], ["EAST", []], ["INDEPENDENT", []], ["CIVILIAN", []]
    ];
};
if (isNil "Waldo_Gunship_FactionAircraftPools") then {Waldo_Gunship_FactionAircraftPools = createHashMap};

if (isNil "Waldo_Hazard_Enable") then {Waldo_Hazard_Enable = false};
if (isNil "Waldo_Hazard_Interval") then {Waldo_Hazard_Interval = 1};
if (isNil "Waldo_Hazard_ShowStatus") then {Waldo_Hazard_ShowStatus = true};
if (isNil "Waldo_Hazard_NotifyTransitions") then {Waldo_Hazard_NotifyTransitions = true};
if (isNil "Waldo_Hazard_NotificationDuration") then {Waldo_Hazard_NotificationDuration = 6};
if (isNil "Waldo_Hazard_Presets") then {
    Waldo_Hazard_Presets = createHashMapFromArray [
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
    ];
};

if (isNil "Waldo_TreeFelling_Enable") then {Waldo_TreeFelling_Enable = false};
if (isNil "Waldo_TreeFelling_Range") then {Waldo_TreeFelling_Range = 3};
if (isNil "Waldo_TreeFelling_BaseHits") then {Waldo_TreeFelling_BaseHits = 3};
if (isNil "Waldo_TreeFelling_HeightFactor") then {Waldo_TreeFelling_HeightFactor = 0.25};
if (isNil "Waldo_TreeFelling_HitCooldown") then {Waldo_TreeFelling_HitCooldown = 0.7};
if (isNil "Waldo_TreeFelling_WeaponPatterns") then {Waldo_TreeFelling_WeaponPatterns = ["axe", "hatchet"]};
if (isNil "Waldo_TreeFelling_FallenClasses") then {Waldo_TreeFelling_FallenClasses = ["Land_WoodenLog_F"]};
if (isNil "Waldo_TreeFelling_FallenClassesSmall") then {Waldo_TreeFelling_FallenClassesSmall = []};
if (isNil "Waldo_TreeFelling_FallenClassesMedium") then {Waldo_TreeFelling_FallenClassesMedium = []};
if (isNil "Waldo_TreeFelling_FallenClassesLarge") then {Waldo_TreeFelling_FallenClassesLarge = []};
if (isNil "Waldo_TreeFelling_SizeThresholds") then {Waldo_TreeFelling_SizeThresholds = [7, 15]};
if (isNil "Waldo_TreeFelling_FallenRandomDirection") then {Waldo_TreeFelling_FallenRandomDirection = true};
if (isNil "Waldo_TreeFelling_DirectionMode") then {Waldo_TreeFelling_DirectionMode = "RANDOM"};
if (isNil "Waldo_TreeFelling_ClearBushes") then {Waldo_TreeFelling_ClearBushes = false};
if (isNil "Waldo_TreeFelling_BushRadius") then {Waldo_TreeFelling_BushRadius = 4};
if (isNil "Waldo_TreeFelling_ToolEfficiency") then {Waldo_TreeFelling_ToolEfficiency = createHashMap};
if (isNil "Waldo_TreeFelling_ProtectedAreas") then {Waldo_TreeFelling_ProtectedAreas = []};
if (isNil "Waldo_TreeFelling_Yields") then {Waldo_TreeFelling_Yields = []};
if (isNil "Waldo_TreeFelling_RegrowSeconds") then {Waldo_TreeFelling_RegrowSeconds = -1};

if (isNil "Waldo_Breaching_Enable") then {Waldo_Breaching_Enable = false};
if (isNil "Waldo_Breaching_Profiles") then {Waldo_Breaching_Profiles = createHashMap};
if (isNil "Waldo_Breaching_ExplosiveStrengths") then {
    Waldo_Breaching_ExplosiveStrengths = createHashMapFromArray [["DemoCharge_Remote_Ammo", 1], ["SatchelCharge_Remote_Ammo", 3]];
};

if (isNil "Waldo_Paradrop_AircraftClasses") then {
    Waldo_Paradrop_AircraftClasses = [
        "B_T_VTOL_01_infantry_F", "O_T_VTOL_02_infantry_dynamicLoadout_F",
        "B_Heli_Transport_03_unarmed_F", "O_Heli_Transport_04_covered_F", "I_Heli_Transport_02_F"
    ];
};
if (isNil "Waldo_Paradrop_StaticChuteClasses") then {Waldo_Paradrop_StaticChuteClasses = ["NonSteerable_Parachute_F"]};
if (isNil "Waldo_Paradrop_HaloBackpackClasses") then {Waldo_Paradrop_HaloBackpackClasses = ["B_Parachute", "O_Parachute", "I_Parachute"]};
if (isNil "Waldo_Paradrop_ChuteClasses") then {Waldo_Paradrop_ChuteClasses = +Waldo_Paradrop_StaticChuteClasses};
if (isNil "Waldo_Paradrop_BoardingPointClasses") then {
    Waldo_Paradrop_BoardingPointClasses = [
        "FlagPole_F", "Land_InfoStand_V1_F", "Land_InfoStand_V2_F", "Land_MapBoard_F",
        "Land_Laptop_unfolded_F", "Land_CampingTable_small_F", "Land_PortableLight_single_F"
    ];
};

if (isNil "Waldo_Economy_Enable") then {Waldo_Economy_Enable = false};
if (isNil "Waldo_MiniGames_Enable") then {Waldo_MiniGames_Enable = true};
if (isNil "Waldo_CorpseTraps_Enable") then {Waldo_CorpseTraps_Enable = false};
if (isNil "ACE_maxWeightDrag") then {ACE_maxWeightDrag = 10000};
if (isNil "ACE_maxWeightCarry") then {ACE_maxWeightCarry = 6000};
if (isNil "ace_hearing_disableVolumeUpdate") then {ace_hearing_disableVolumeUpdate = true};

if (isNil "Waldo_AIRebalance_Enable") then {Waldo_AIRebalance_Enable = true};
if (isNil "Waldo_AIRebalance_Mode") then {Waldo_AIRebalance_Mode = missionNamespace getVariable ["Waldo_AI_Mode", "DAY"]};
if (isNil "Waldo_AIRebalance_Profile") then {Waldo_AIRebalance_Profile = "LINE"};
if (isNil "Waldo_AI_ApplyMode") then {Waldo_AI_ApplyMode = "BOTH"};
if (isNil "Waldo_AI_RestoreOnStop") then {Waldo_AI_RestoreOnStop = true};
if (isNil "Waldo_AI_SkillVariance") then {Waldo_AI_SkillVariance = 0};
if (isNil "Waldo_AI_IncludedSides") then {Waldo_AI_IncludedSides = []};
if (isNil "Waldo_AI_IncludedFactions") then {Waldo_AI_IncludedFactions = []};
if (isNil "Waldo_AI_ExcludedFactions") then {Waldo_AI_ExcludedFactions = []};
if (isNil "Waldo_AI_ExcludedClasses") then {Waldo_AI_ExcludedClasses = []};
if (isNil "Waldo_ImprovedHelicopterLanding_Enable") then {Waldo_ImprovedHelicopterLanding_Enable = true};
if (isNil "Waldo_ImprovedHelicopterLanding_MinimumActivationDistance") then {Waldo_ImprovedHelicopterLanding_MinimumActivationDistance = 50};
if (isNil "Waldo_ImprovedHelicopterLanding_TriggerDistance") then {Waldo_ImprovedHelicopterLanding_TriggerDistance = 500};
if (isNil "Waldo_ImprovedHelicopterLanding_TriggerSpeedFactor") then {Waldo_ImprovedHelicopterLanding_TriggerSpeedFactor = 4.2};
if (isNil "Waldo_ImprovedHelicopterLanding_TransitAltitude") then {Waldo_ImprovedHelicopterLanding_TransitAltitude = 30};
if (isNil "Waldo_ImprovedHelicopterLanding_GlideSlopeRatio") then {Waldo_ImprovedHelicopterLanding_GlideSlopeRatio = 4};
if (isNil "Waldo_ImprovedHelicopterLanding_TreeScanRadius") then {Waldo_ImprovedHelicopterLanding_TreeScanRadius = 25};
if (isNil "Waldo_ImprovedHelicopterLanding_TreeSafetyBuffer") then {Waldo_ImprovedHelicopterLanding_TreeSafetyBuffer = 5};
if (isNil "Waldo_ImprovedHelicopterLanding_MaximumTreeHoverHeight") then {Waldo_ImprovedHelicopterLanding_MaximumTreeHoverHeight = 40};
if (isNil "Waldo_ImprovedHelicopterLanding_GoAroundTriggerDistance") then {Waldo_ImprovedHelicopterLanding_GoAroundTriggerDistance = 200};
if (isNil "Waldo_ImprovedHelicopterLanding_GoAroundHeight") then {Waldo_ImprovedHelicopterLanding_GoAroundHeight = 150};
if (isNil "Waldo_ImprovedHelicopterLanding_GoAroundExitDistance") then {Waldo_ImprovedHelicopterLanding_GoAroundExitDistance = 250};
if (isNil "Waldo_ImprovedHelicopterLanding_GoAroundSpeed") then {Waldo_ImprovedHelicopterLanding_GoAroundSpeed = 70};
if (isNil "Waldo_ImprovedHelicopterLanding_MaximumGoArounds") then {Waldo_ImprovedHelicopterLanding_MaximumGoArounds = 1};
if (isNil "Waldo_ImprovedHelicopterLanding_MaximumClimbRate") then {Waldo_ImprovedHelicopterLanding_MaximumClimbRate = 8};
if (isNil "Waldo_ImprovedHelicopterLanding_MaximumDescentRate") then {Waldo_ImprovedHelicopterLanding_MaximumDescentRate = 10};
if (isNil "Waldo_ImprovedHelicopterLanding_TouchdownRadius") then {Waldo_ImprovedHelicopterLanding_TouchdownRadius = 2};
if (isNil "Waldo_ImprovedHelicopterLanding_FinalCommitDistance") then {Waldo_ImprovedHelicopterLanding_FinalCommitDistance = 75};
if (isNil "Waldo_ImprovedHelicopterLanding_ControlInterval") then {Waldo_ImprovedHelicopterLanding_ControlInterval = 0.05};
if (isNil "Waldo_ImprovedHelicopterLanding_TouchdownHoldSeconds") then {Waldo_ImprovedHelicopterLanding_TouchdownHoldSeconds = 8};
if (isNil "Waldo_AI_ProfileDisplayNames") then {
    Waldo_AI_ProfileDisplayNames = createHashMapFromArray [
        ["LEGACY", "Existing Mission Balance"], ["MILITIA", "WMP Militia"],
        ["LINE", "WMP Line"], ["VETERAN", "WMP Veteran"], ["ELITE", "WMP Elite"]
    ];
};

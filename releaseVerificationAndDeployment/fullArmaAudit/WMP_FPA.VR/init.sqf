// Generated full-pack audit entry point. Keep the real pack lifecycle intact.
call compile preprocessFileLineNumbers "auditBootstrap.sqf";
call compile preprocessFileLineNumbers "auditPreInit.sqf";

/*
 * Author: WaldoTheWarfighter
 * Defines shared WMP mission configuration and starts systems whose state or behavior is consumed
 * on every machine. Guarded defaults preserve authoritative live changes for JIP clients.
 *
 * Arguments: None.
 * Return Value: Nothing; initializes shared mission state and schedules feature startup.
 *
 * Example: Arma executes init.sqf automatically during mission initialization.
 * Current caller: the Arma mission initialization sequence on server, clients and headless clients.
*/

//Lighting Setup Engine - Optional
//"LightShafts" ppEffectAdjust [0.9, 0.8, 0.9, 0.8];

//Third Party Scripts (Look at mentioned file to enable
//[] execVM "MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf";


/*
Optional feature systems

Shared configuration lives here only when both authority and clients consume it. Player-only
configuration and activation live in initPlayerLocal.sqf; server-only configuration and activation
live in initServer.sqf. Guarded local defaults preserve server-published mid-mission changes for JIP.
*/
// Visual-only global UI style: DEFAULT | WW2 | VIETNAM | SCIFI.
// Set this before the guarded default to choose the mission's presentation without changing behavior.
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

// Squad rally points are disabled by default and may also be configured live through ZEN.
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

// Vehicle recovery is activated by registering workshops and vehicles. The scan is server-only.
if (isNil "Waldo_Recovery_ScanInterval") then {Waldo_Recovery_ScanInterval = 3};
if (isNil "Waldo_Recovery_NotificationRadius") then {Waldo_Recovery_NotificationRadius = 100};
if (isNil "Waldo_Recovery_CreateWorkshopMarkers") then {Waldo_Recovery_CreateWorkshopMarkers = true};
if (isNil "Waldo_Recovery_PlacementClearance") then {Waldo_Recovery_PlacementClearance = 3};
if (isNil "Waldo_Recovery_DefaultCustomVariables") then {Waldo_Recovery_DefaultCustomVariables = []};
if (isNil "Waldo_Recovery_PackageClasses") then {
    Waldo_Recovery_PackageClasses = ["B_Slingload_01_Cargo_F", "Land_Pallet_MilBoxes_F"];
};

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
if (isNil "Waldo_TreeFelling_DirectionMode") then {Waldo_TreeFelling_DirectionMode = "RANDOM"}; // RANDOM | ORIGINAL | STRIKE
if (isNil "Waldo_TreeFelling_ClearBushes") then {Waldo_TreeFelling_ClearBushes = false};
if (isNil "Waldo_TreeFelling_BushRadius") then {Waldo_TreeFelling_BushRadius = 4};
if (isNil "Waldo_TreeFelling_ToolEfficiency") then {Waldo_TreeFelling_ToolEfficiency = createHashMap};
if (isNil "Waldo_TreeFelling_ProtectedAreas") then {Waldo_TreeFelling_ProtectedAreas = []};
if (isNil "Waldo_TreeFelling_Yields") then {Waldo_TreeFelling_Yields = []};
if (isNil "Waldo_TreeFelling_RegrowSeconds") then {Waldo_TreeFelling_RegrowSeconds = -1};

if (isNil "Waldo_Breaching_Enable") then {Waldo_Breaching_Enable = false};
if (isNil "Waldo_Breaching_Profiles") then {Waldo_Breaching_Profiles = createHashMap};
if (isNil "Waldo_Breaching_ExplosiveStrengths") then {
    Waldo_Breaching_ExplosiveStrengths = createHashMapFromArray [
        ["DemoCharge_Remote_Ammo", 1], ["SatchelCharge_Remote_Ammo", 3]
    ];
};
missionNamespace setVariable ["Waldo_SharedFeatureConfigReady", true];
if (isServer) then {
    missionNamespace setVariable ["Waldo_FeatureRuntimeSnapshotReceived", true];
    missionNamespace setVariable ["Waldo_FeatureRuntimeSnapshotFailed", false];
} else {
    missionNamespace setVariable ["Waldo_FeatureRuntimeSnapshotReceived", false];
    missionNamespace setVariable ["Waldo_FeatureRuntimeSnapshotFailed", false];
    [] call Waldo_fnc_FeatureRuntimeRequestState;
};

// Dynamic paradrop operations. Airframe availability is independent from operational side and
// mission makers may extend these arrays with mod aircraft/chutes before init.sqf runs.
if (isNil "Waldo_Paradrop_AircraftClasses") then {
    Waldo_Paradrop_AircraftClasses = [
        "B_T_VTOL_01_infantry_F",
        "O_T_VTOL_02_infantry_dynamicLoadout_F",
        "B_Heli_Transport_03_unarmed_F",
        "O_Heli_Transport_04_covered_F",
        "I_Heli_Transport_02_F"
    ];
};
if (isNil "Waldo_Paradrop_StaticChuteClasses") then {
    Waldo_Paradrop_StaticChuteClasses = ["NonSteerable_Parachute_F"];
};
if (isNil "Waldo_Paradrop_HaloBackpackClasses") then {
    Waldo_Paradrop_HaloBackpackClasses = ["B_Parachute", "O_Parachute", "I_Parachute"];
};
// Compatibility alias for missions that extended the original combined list.
if (isNil "Waldo_Paradrop_ChuteClasses") then {
    Waldo_Paradrop_ChuteClasses = +Waldo_Paradrop_StaticChuteClasses;
};
if (isNil "Waldo_Paradrop_BoardingPointClasses") then {
    Waldo_Paradrop_BoardingPointClasses = [
        "FlagPole_F",
        "Land_InfoStand_V1_F",
        "Land_InfoStand_V2_F",
        "Land_MapBoard_F",
        "Land_Laptop_unfolded_F",
        "Land_CampingTable_small_F",
        "Land_PortableLight_single_F"
    ];
};
[] spawn {
    waitUntil {
        missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
        || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
    };
    if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) exitWith {};
    if (missionNamespace getVariable ["Waldo_Breaching_Enable", false]) then {
        [] call Waldo_fnc_BreachingInit;
    };
};

/*
Waldos Economy Systems (Resource / Research / Build / Buy + Ground Command)

A pub-Zeus economy suite: define resources, capturable income zones and collectable crates,
run research at a Research Center, construct and upgrade buildings, and let players buy vehicles.
A trusted "Ground Command" controls spending. Everything is driven live from the Zeus menu
"Waldos Economy Systems" - no editor work required beyond enabling it.

Set the flag below to true to start the economy suite (runs on all machines; it self-branches
between the server authority loops and the client Zeus menu). It is OFF by default so missions
that do not use it pay no cost. You can also enable it without editing this file by dropping the
"[WMP] Waldos Economy Systems" composition (its object boots the suite from its own init).

To pre-configure the economy from the editor (a bundled LOW/MEDIUM/HIGH preset, a full exported
config string, or commitment mode) without opening Zeus, see the "Waldos Economy Systems"
setup block in initServer.sqf.

Full guide (easiest path first): https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems
*/
// Respect configuration supplied before the pack entry point runs. This is useful for
// generated missions and scripted deployments while retaining the normal disabled default.
Waldo_Economy_Enable = missionNamespace getVariable ["Waldo_Economy_Enable", false];
// Activation is deliberately deferred to initServer.sqf and initPlayerLocal.sqf.
// The server must publish its preset/configuration before Economy reads it; starting here can
// race initServer.sqf and leave an enabled economy with empty catalogues.

/*
Waldos Mini Games (table party games + interaction procedures)

Two complementary systems under one feature:

  1. Table games - a seated, multiplayer party-games engine with twelve games including Texas
     Hold'em, Five-Card Draw, Liar's Dice and Connect Four. Place any supported table object (a
     camping table by default) in Eden and players get actions to sit, vote and play. Runs on all
     machines (server authority + client UI) and is JIP-safe. This installer is repeat-safe.

  2. Interaction procedures - ten single-player field-equipment procedures that resolve to an
     authoritative outcome and can gate any object interaction (see Waldo_fnc_MiniGameInteraction
     / Waldo_fnc_BombDefuseSetup). They register on first use and are independent of this flag.

Set the flag to false if your mission uses no table games (the interaction challenges are
unaffected). Full guide: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games
*/
if (isNil "Waldo_MiniGames_Enable") then {Waldo_MiniGames_Enable = true};
if (Waldo_MiniGames_Enable) then {
    [] call Waldo_fnc_MiniGamesInit;
};

/*
ACE Corpse Traps

Lets players consume a carried throwable to rig any corpse through ACE interaction. The exact
magazine is preserved, so vanilla and modded frag, smoke, flashbang, incendiary and utility
throwables use their own projectile behaviour when somebody opens the body's inventory.

This is deliberately OFF by default because it changes a familiar inventory interaction into a
lethal risk. Full guide: https://github.com/AdamWaldie/WaldosMissionPack/wiki/ACE-Corpse-Traps
*/
if (isNil "Waldo_CorpseTraps_Enable") then {Waldo_CorpseTraps_Enable = false};
if (Waldo_CorpseTraps_Enable) then {
    [] call Waldo_fnc_CorpseTrapInit;
};

/*
After-Action WIA listener (ACE)

ACE raises "ace_unconscious" locally on the machine owning the unit, so it cannot be caught by the
server-only EntityKilled handler in Waldo_fnc_AARTrack. This all-machines listener forwards each
unit's first unconsciousness to the server (Waldo_fnc_AARWound) so the ENDEX debrief can show WIA
per side. Counts each unit once. Silently absent if ACE medical is not loaded.
*/
if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then {
    ["ace_unconscious", {
        params ["_unit", "_state"];
        if (_state && {local _unit} && {!(_unit getVariable ["Waldo_AAR_Wounded", false])}) then {
            _unit setVariable ["Waldo_AAR_Wounded", true];
            [[west, east, independent, civilian] find (side group _unit)] remoteExec ["Waldo_fnc_AARWound", 2];
        };
    }] call CBA_fnc_addEventHandler;
};

/*===========================================================================================================================*/

//Set ace namespace variables for maximum drag/carryweights (Tune these so that you can carry/drag your logistics boxes ingame)
ACE_maxWeightDrag = 10000;
ACE_maxWeightCarry = 6000;


/*===========================================================================================================================*/

// Note that its due to Ace Hearing fucking with CBA & Vanilla audio commands (https://github.com/acemod/ACE3/issues/4029)
ace_hearing_disableVolumeUpdate = true;


/*===========================================================================================================================*/

/*
AI Tweak setup
These commands initiate Waldos AI Tweaks. It is an Either/OR situation, where the DAY OR NIGHT mode can be active per mission.
Daytime Mission parameter - uncomment this for daytime AI values.
*/
if (isNil "Waldo_AIRebalance_Enable") then {Waldo_AIRebalance_Enable = true};
if (isNil "Waldo_AIRebalance_Mode") then {Waldo_AIRebalance_Mode = missionNamespace getVariable ["Waldo_AI_Mode", "DAY"]};
if (isNil "Waldo_AIRebalance_Profile") then {Waldo_AIRebalance_Profile = "LINE"};
if (isNil "Waldo_AI_ApplyMode") then {Waldo_AI_ApplyMode = "BOTH"}; // BOTH | EXISTING | NEW
if (isNil "Waldo_AI_RestoreOnStop") then {Waldo_AI_RestoreOnStop = true};
if (isNil "Waldo_AI_SkillVariance") then {Waldo_AI_SkillVariance = 0};
if (isNil "Waldo_AI_IncludedSides") then {Waldo_AI_IncludedSides = []};
if (isNil "Waldo_AI_IncludedFactions") then {Waldo_AI_IncludedFactions = []};
if (isNil "Waldo_AI_ExcludedFactions") then {Waldo_AI_ExcludedFactions = []};
if (isNil "Waldo_AI_ExcludedClasses") then {Waldo_AI_ExcludedClasses = []};
// Event-driven AI helicopter landing assistance. Per-aircraft HashMap overrides may be stored in
// Waldo_ImprovedHelicopterLanding_Profile; set Waldo_ImprovedHelicopterLanding_Exclude to opt out.
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
[] spawn {
    waitUntil {
        missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
        || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
    };
    if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) exitWith {};
    if (missionNamespace getVariable ["Waldo_AIRebalance_Enable", true]) then {
        [
            missionNamespace getVariable ["Waldo_AIRebalance_Mode", "DAY"],
            missionNamespace getVariable ["Waldo_AIRebalance_Profile", "LINE"]
        ] call Waldo_fnc_AITweak;
    };
    [] call Waldo_fnc_ImprovedHelicopterLandingInit;
};
// Nightime Mission - uncomment this for nightime AI values.
//"NIGHT" call Waldo_fnc_AITweak;


/*===========================================================================================================================*/


/*
ACRE 2 RADIO SETUP PARAMETERS

This section deals with setting up preset radio channels. Channel Naming is currently unavailable as it causes ACRE radios to be inconsistent.

You can set which squads are assigned to which of the channels you have chosen. Side does not matter here.

The format is as follows ["Squad Name",["ChannelSelection1","ChannelSelection2","ChannelSelection3"] where the Squad name is idential to the group name you picked earlier.
ChannelSelection1 though 3 should match one channel in the LongRangeRadioChannel for the side of that squad. You can have up to three choices,
however this is limited by the number of AN/PRC-152,AN/PRC-148 and AN/PRC-117F radios on that squad.
You should enter channels based on the range required. E.g. Platoon Net followed by Air2Ground or Company Net.

AN/PRC-343 Radios are done automatically based on squad callsign and Numerical designations (if any).

ACRE CEOI in the map screen will note all channel assignments for referance.

*/

private _RadioSetups = [
    ["Viking-1-1",[1,5]],
	["Viking 5",[2,7]],
	["Viking 3.2",[3,2]],
	["Banshee",[4,1]]
];
// ACRE setup deliberately enters on every machine: the server publishes the shared
// callsign/channel allocation, while interface clients configure their own radios and CEOI.
// Waldo_fnc_ACRE2Init exits on a dedicated server before touching player or ACRE client state.
[_RadioSetups] spawn Waldo_fnc_ACRE2Init;


/*
ACRE 2 Babel Setup

The script activates the Babel system in Arma 3 with Advanced Combat Radio Environment 2 (ACRE2). It sets up the languages spoken by different sides and defines the languages spoken by interpreters.
It adds all the necessary languages to the ACRE2 Babel system, assigns them to the respective units based on the side they belong to, and creates a diary record with a list of languages spoken in the area.

Arguments:
_languages - An array of sub-arrays. Each sub-array contains a side (West, East, Independent, Civilian) and the languages they speak as strings.
_interpreters - An array of units that are interpreters. These units can speak all languages.

Example:
[
    [
        [West, "English","French"],
        [East, "Chinese"],
        [independent, "Altian"],
        [civilian, "Altian"]
    ],
    [unit, unit2]
] call Waldo_fnc_BabelActivation;

*/
/*
[
	[
		[west, "English", "French"],
		[east, "Russian"],
		[civilian, "French"]
	]
] call Waldo_fnc_BabelActivation;
*/
/*
ACRE 2 CEOI

The Below list are named channels for you to assign names to. These names will appear in the CEOI, and assigned appropriately to a channel number from 1 to 99.
The position of each channel in the list determines which channel number it will be assigned in the CEOI. E.g. The second Entry ("PLATOON 2" in the example given) will be channel 2 in the CEOI.

This is broken down per Side as displayed.

*/

_LongRangeRadioChannels_BLUFOR = ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"];
missionNamespace setVariable ["Waldo_ACRE2Setup_LRChannels_BLUFOR", _LongRangeRadioChannels_BLUFOR];
_LongRangeRadioChannels_OPFOR = ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"];
missionNamespace setVariable ["Waldo_ACRE2Setup_LRChannels_OPFOR", _LongRangeRadioChannels_OPFOR];
_LongRangeRadioChannels_IND = ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"];
missionNamespace setVariable ["Waldo_ACRE2Setup_LRChannels_IND", _LongRangeRadioChannels_IND];
_LongRangeRadioChannels_CIV = ["PLATOON 1","PLATOON 2","PLATOON 3","COMPANY","AIR 2 GROUND","AIR 2 AIR","CAS 1","CAS 2","CFF 1","CFF 2","CONVOY 1"];
missionNamespace setVariable ["Waldo_ACRE2Setup_LRChannels_CIV", _LongRangeRadioChannels_CIV];


/*===========================================================================================================================*/

/*
Localised Radio Jamming (ACRE2 / TFAR)

Area-denial radio jamming for both ACRE2 and TFAR. A "jammer" is any object with a radius: radios
inside its field (ACRE2) or players standing in it (TFAR) lose comms, with a linear falloff at the
edge. You can jam everyone or only chosen sides, and (ACRE2 only) restrict it to frequency bands.

Set up jammers however suits you:
- From an object's init field in Eden:      [this] call Waldo_fnc_Jammer;                  // 300 m, jams all
                                            [this, 500, "EAST"] call Waldo_fnc_Jammer;      // 500 m, OPFOR only
- From a trigger / script:                  [myTower, 800, "ALL", [[30,88]]] call Waldo_fnc_Jammer;
- Live from Zeus ("Waldos Mission Modules"): Radio Jammer - Place / Toggle Nearest / Remove Nearest.

Toggle or remove later with [ref, active] call Waldo_fnc_JammerToggle; and [ref] call Waldo_fnc_JammerRemove;
(ref = the jammer object or the id returned by Waldo_fnc_Jammer).

ACRE2 note: your ACRE2 signal model must be "LOS Multipath" (the default) or "Arcade" for jamming to
apply. Full guide: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Radio-Jamming

The feature installs its radio engines only while enabled; with no jammers placed it has no effect.
Set Waldo_Jamming_Enable to false to disable it entirely; Waldo_Jamming_Notify controls the on-screen
jamming meter players see when they enter a field.

Model options (tune the realism/gameplay to taste):
- Waldo_Jamming_LOS            true  = terrain/hills block the jamming field (line of sight)
- Waldo_Jamming_BurnThrough    true  = higher-power radios (e.g. PRC-117F) resist jamming, shrinking
                                       the effective field; Waldo_Jamming_BurnThroughRef is the mW
                                       reference power (a radio at this power is fully affected)
- Waldo_Jamming_Curve          "LINEAR" or "INVSQ" edge falloff
- Waldo_Jamming_Destructible   true  = destroying a jammer's object removes it (EW objectives)
- Waldo_Jamming_GmOverlay      false = optional curator-only jammer marker and facing line
- Waldo_Jamming_ScanRange      hard detection cap (m); RDF reports only sources whose active field currently reaches the operator
- Waldo_Jamming_ScanBearingArc width (deg) of the reported bearing sector
- Waldo_Jamming_ScanDistanceBands absolute metre thresholds for VERY CLOSE / NEARBY / DISTANT; beyond the third is VERY DISTANT
- Waldo_Jamming_DisableChallenge false = legacy instant engineer disable; true = shared field procedure
- Waldo_Jamming_DisableChallengeId "circuit" and Waldo_Jamming_DisableDifficulty "standard"
- Waldo_Jamming_DisableEngineerOnly true = server and client both require ACE engineer capability
- Waldo_Jamming_DisableResult "DISABLE" preserves the emitter for curator reactivation; "DESTROY" removes it
- Waldo_Jamming_AllowPlayerToggle true = legacy direct toggle on non-challenge emitters only
*/
// Authoritative jamming configuration is established once in initServer.sqf and
// consumed by each joining player in initPlayerLocal.sqf. Do not broadcast defaults
// here: init.sqf runs again on JIP clients and would overwrite live server/Zeus state.


/*===========================================================================================================================*/

/*
Vehicle function eventhandler

This adds vehicle functions to affected vehicles:
- Get out on specfic side. Only affects RHS gear so far.
- Auto added medical/logistics status to vehicles.  Only affects RHS gear so far.
- HALO / Static line [WIP] Only affects RHS gear so far.

*/
call Waldo_fnc_InitVehicles;

/*

Briefing documents

*/
if (hasInterface) then {call Waldo_fnc_AddDocs};

/*

Sets team colour based on contents of role description.
Colour selections are RED,BLUE,GREEN,YELLOW.
Name Selections are ALPHA,BRAVO,CHARLIE,DELTA - which maps to colours as in colour selections.
Role selections are SQUAD Leader (Yellow), MEDIC (Green).

Currently based on the first word in the role description.

So Squad Leader will trigger assignment as Yellow but Viking Squad Leader will not- will likely refine this later.

*/
if (hasInterface) then {call Waldo_fnc_SetTeamColour};

/*===========================================================================================================================*/

/*
Introduction Text - Cool Introduction stuff like location, date, time and mission name and locale

When left with no parameters, as below, the script autogenerates the location based on the terrain name, and the mission title from the description.ext
You can optionally define replacements for the title & location, as is demonstrated in the trigger in the exemplar mission.
*/
// Player presentation requires display 46. Running InfoText on a dedicated server
// waits forever for a display that cannot exist and blocks WALDO_INIT_COMPLETE.
if (hasInterface) then {["",""] call Waldo_fnc_InfoText};

/*

waldos Init Completion flag

======DO NOT TOUCH!=====
*/
sleep 10; // Buffer cycles for other inits to be completed - should not be removed
// A dedicated server has no local player. Waiting for one here prevented the pack's
// completion flag and any post-start consumers from ever running on that machine.
waitUntil {isDedicated || {!isNull player && {player == player}}};
// Per-machine readiness: a client must not mark the server (or another JIP client)
// complete. Every machine reaches this only after its own shared init chain finishes.
missionNamespace setVariable ["WALDO_INIT_COMPLETE", true];

call compile preprocessFileLineNumbers "auditInit.sqf";

/*
 * Author: WaldoTheWarfighter
 * Defines field-resupply, vehicle-recovery, transport-service, object-scaling and logistics-crate defaults. World
 * mutation remains server-authoritative and object interactions remain client-local/JIP-safe.
 *
 * Schema: SHARED entries are [name, default]; SERVER entries are [name, default, publish BOOL].
 * CONDITIONAL entries are [scope, name, required CfgPatches class, loaded default, absent default,
 * publish BOOL]. Arguments: None. Return Value: HASHMAP consumed by the feature-config loader.
 *
 * Example: add compatible recovery package classes to Waldo_Recovery_PackageClasses.
 * Result: registered recovery carriers may virtualise a package using the ordered valid class pool.
 * Current callers: init.sqf (SHARED) and initServer.sqf (SERVER) through the loader.
 *
 * ACTIVATION MODEL: REGISTERED OBJECTS / CALL-DRIVEN.
 * Field resupply requires a registered hub and assigned carriers; vehicle recovery requires a
 * workshop plus registered recoverable vehicles and optional package carriers. Object scaling is
 * performed only by its script/ZEN operation. Crate class settings are consumed by existing WMP
 * spawners and do not create crates on their own.
 *
 * EDIT FOR A NORMAL MISSION: resupply content/balance, recovery package/marker policy, scaling
 * limits and crate classes. LEAVE ALONE UNLESS EXTENDING/TESTING: scans, safe-placement geometry and
 * client authority. CUSTOM CALLS: use initServer.sqf for Waldo_fnc_FieldResupplyRegisterHub,
 * Waldo_fnc_FieldResupplyAssignCarrier and RecoveryRegister* pre-planning; editor object-init calls
 * are repeat-safe/server-routed where their function header explicitly demonstrates `[this,...]`.
 *
 * CUSTOMISATION GUIDE:
 * MISSION MAKER - field-resupply enablement/content, carrier capacity, recovery package classes,
 * workshop markers, object-scale bounds and logistics crate classes are intended choices.
 * A deployed field-resupply crate's content is entirely governed by
 * Waldo_fnc_SupplyCratePopulate's own side scan (Logi_MissionSQMArray_*, the same pool starter/logi
 * crates already draw from) - there is no separate magazine allow/block list to configure here.
 * Recovery custom variables use the documented serialisable variable schema.
 * ADVANCED TUNING - recovery scan interval/clearance and client scale requests affect balance,
 * traffic or placement safety. Intervals are seconds, radii/clearance are metres and object scale is
 * a positive multiplier. Client scale requests should normally remain false. Medical crate selection
 * is dependency-sensitive and normally automatic.
 *
 * HOW TO READ THE DATA BELOW:
 * `shared` rows are `[variable, default]`. `server` rows are `[variable, default, publish]` where
 * publish true sends the authoritative value to clients/JIP. `conditional` rows are
 * `[scope, variable, required CfgPatches class, value when present, value when absent, publish]`.
 * None of these rows creates a hub, carrier, workshop or crate by itself.
 * Recovery DefaultCustomVariables is an ARRAY of variable-name STRINGs; only serialisable values
 * are copied into a vehicle package. PackageClasses is an ordered fallback pool of CfgVehicles
 * classes and may be overridden per registered vehicle.
 *
 * SETTING-BY-SETTING GUIDE - RESPAWN LOADOUT:
 * - Waldo_Respawn_SaveOnDeath (MISSION MAKER): off by default. false = respawn uses the mission-start
 *   baseline plus the last manual Loadout Save Point action; true = a "CAManBase"/"Killed" handler in
 *   initPlayerLocal.sqf captures loadout+radio on every death and restores it on respawn instead.
 *
 * SETTING-BY-SETTING GUIDE - SIDE-SWITCH RESPAWN SEEDING:
 * The first time a live side change (Zeus/admin reassignment, a mission-specific faction-switch
 * feature) lands a player on a side with no snapshot saved yet, one is always seeded automatically per
 * Waldo_Respawn_SideSwitchMode below - a player moved mid-mission is never simply dumped on the class
 * default (RESPAWN_BASELINE) with no gear that matches what they were just doing. There is no on/off
 * switch for this: leaving a side-switched player on bare class gear until they think to manually save
 * is never a desirable outcome, so it is not a mission-maker decision to gate. A side that already has
 * its own saved snapshot is never touched by this - only the normal respawn-restore path ever applies
 * it.
 * - Waldo_Respawn_SideSwitchMode (MISSION MAKER): "CARRY_OVER" (default) seeds from the player's
 *   current live gear and radios exactly as-is, tagged BRIDGED - a deliberate live bridge back to
 *   their old side's kit and radio presets, since ACRE2 never re-syncs a switched player's preset on
 *   its own. "SIDE_BASE_LOADOUT" instead assembles a weapon-aware starter kit from the new side's own
 *   scanned mission.sqm pool with that side's proper ACRE2 preset, tagged NATIVE; if that side has no
 *   usable pool it automatically falls back to CARRY_OVER. Any value other than exactly
 *   "SIDE_BASE_LOADOUT" behaves as CARRY_OVER (an unrecognized string is logged to RPT, not rejected).
 *
 * SETTING-BY-SETTING GUIDE - FIELD RESUPPLY:
 * - Waldo_FieldResupply_Enable (MISSION MAKER): permits hubs/actions; register a hub and assign carriers separately.
 * - Waldo_FieldResupply_CrateClass (MISSION MAKER): valid CfgVehicles crate spawned and populated for each deployment.
 * - Waldo_FieldResupply_DefaultCarrierCapacity (MISSION MAKER): logical crates granted to a newly assigned carrier.
 * - Waldo_FieldResupply_CrateSizeScalar (MISSION MAKER): multiplies the populated magazine/item/weapon quantities.
 * - Waldo_FieldResupply_IncludeWeaponsAttachments (MISSION MAKER): also populate weapons, attachments and clothing.
 * - Waldo_FieldResupply_IncludeLaunchers (MISSION MAKER): also populate launchers and launcher ammunition.
 * - Waldo_FieldResupply_RetainOnRespawn (MISSION MAKER): preserves that player's carrier allowance after respawn.
 *
 * SETTING-BY-SETTING GUIDE - VEHICLE RECOVERY:
 * - Waldo_Recovery_ScanInterval (ADVANCED): seconds between carrier/package state checks; lower costs more server time.
 * - Waldo_Recovery_NotificationRadius (MISSION MAKER): completed-recovery messages reach players this near the workshop.
 * - Waldo_Recovery_CreateWorkshopMarkers (MISSION MAKER): creates an area marker and exact-position marker per workshop.
 * - Waldo_Recovery_PlacementClearance (ADVANCED): extra metres required around the restored vehicle footprint.
 * - Waldo_Recovery_DefaultCustomVariables (MISSION MAKER): serialisable object-variable names copied for every vehicle.
 * - Waldo_Recovery_PackageClasses (MISSION MAKER): ordered fallback CfgVehicles classes for virtualised packages.
 *
 * SETTING-BY-SETTING GUIDE - SCALING AND CRATES:
 * - Waldo_ObjectScaling_Minimum (MISSION MAKER): smallest positive scale accepted by the server.
 * - Waldo_ObjectScaling_Maximum (MISSION MAKER): largest scale accepted; must not be smaller than Minimum.
 * - Waldo_ObjectScaling_AllowClientRequests (ADVANCED): normally false; server/ZEN remains scaling authority.
 * - Logi_SupplyBoxClass (MISSION MAKER): valid CfgVehicles supply crate used by logistics spawners.
 * - Logi_MedicalBoxClass (AUTOMATIC): ACE crate when ACE medical exists, otherwise the vanilla fallback.
 *
 * SETTING-BY-SETTING GUIDE - TRANSPORT SERVICES:
 * - Waldo_TransportServices_Enable: permits registered helicopter, ground and boat transport services; creates none.
 * - Waldo_Transport_TravelTimeout: maximum seconds allowed for one physical journey before failure recovery.
 * - Waldo_Transport_DefaultBoardingSeconds: maximum pickup wait before an unused service returns to base.
 * - Waldo_Transport_DefaultDestinationDwell: seconds before optional forceDisembark requests player exits; it never permits occupied RTB.
 * - Waldo_Transport_DestinationSettleSeconds (ADVANCED): continuous grounded/slow time before automatic RTB.
 * - Waldo_Transport_DestinationEmptyConfirmSeconds (ADVANCED): continuous human-empty time before automatic RTB.
 * - Waldo_Transport_DestinationSettleSpeedKph (ADVANCED): maximum speed still considered safely settled.
 * - Waldo_HeliTransport_DefaultAltitude: default transit height in metres for registered helicopters.
 * - Waldo_HeliTransport_DefaultLzSearchRadius: furthest a safe helicopter LZ may move from the map click.
 * - Waldo_HeliTransport_DefaultLzClearanceScale: scales the aircraft's real model footprint when testing an LZ.
 * - Waldo_HeliTransport_DefaultSeparation: minimum spacing between helicopter service points and bases.
 * - Waldo_GroundTransport_DefaultRoadSearchRadius: road search around a clicked ground-transport position.
 * - Waldo_GroundTransport_DefaultSeparation: minimum spacing between ground service points and bases.
 * - Waldo_GroundTransport_DefaultSpeedLimit: road-safe AI transport speed cap in kilometres per hour.
 * - Waldo_BoatTransport_DefaultWaterSearchRadius: furthest a safe open-water service point may move from the map click.
 * - Waldo_BoatTransport_DefaultSeparation: minimum spacing between boat service points and bases.
 * - Waldo_BoatTransport_DefaultSpeedLimit: AI boat transport speed cap in kilometres per hour.
 * - Waldo_Transport_DefaultPathRetrySeconds: no-progress interval before a ground or boat driver is reordered.
 * - Waldo_Transport_DefaultPathRetryLimit: maximum automatic ground/boat movement reorders per journey.
 * - Waldo_Transport_MaxEffectiveDamage: damage fraction (0-1) at or above which a still-"alive"
 *   transport is treated as combat-ineffective and written off the same as an outright loss - a
 *   vehicle limping along at 95% damage was previously left in the pool looking fully available.
 *
 * BEGINNER EXAMPLES:
 * - Field resupply: enable it, then place `[this] call Waldo_fnc_FieldResupplyRegisterHub;` on a hub
 *   only if that function's current header lists object-init use; otherwise register from initServer.sqf.
 * - Recovery: register a workshop, recoverable vehicles and optional carrier separately. PackageClasses
 *   changes the visual/physical container pool; it does not make an arbitrary truck a carrier.
 * - Custom variables: `["MyMission_DoorState", "MyMission_CargoCount"]` copies only those values
 *   when they are serialisable; code, UI controls and local object references are not safe save data.
 */
createHashMapFromArray [
    ["featureFamilies", ["Field Resupply", "Vehicle Recovery", "Helicopter Transport", "Ground Transport", "Boat Transport", "Object Scaling", "Logistics Crates", "Respawn Loadout"]],
    ["shared", [
        // MISSION MAKER: respawn loadout capture policy. Default is OFF - the mission-start baseline
        // (initPlayerLocal.sqf) plus the manual "Loadout Save Point" ACE/vanilla action
        // (Waldo_fnc_SaveLoadout, Zen_loadoutSaveSetup.sqf) are the respawn source unless a mission
        // maker opts into automatic death capture here. Consumed by the "CAManBase"/"Killed" handler
        // in initPlayerLocal.sqf, which registers only when this is true.
        ["Waldo_Respawn_SaveOnDeath", false], // BOOL: capture loadout+radio on every death; respawn restores it instead of the last manual/mission-start save.
        // MISSION MAKER: side-switch respawn seeding always runs (see the SETTING-BY-SETTING GUIDE
        // above) - the only choice is which mode. Consumed by initPlayerLocal.sqf's live "group"
        // side-change watcher and Waldo_fnc_RespawnSeedSideSwitch, which only ever seeds a side with
        // no existing snapshot.
        ["Waldo_Respawn_SideSwitchMode", "CARRY_OVER"], // STRING: CARRY_OVER (default, tagged BRIDGED) or SIDE_BASE_LOADOUT (tagged NATIVE, falls back to CARRY_OVER if the side's pool is unusable).
        // MISSION MAKER: field-resupply content and balance. A deployed crate is populated exactly
        // like a standard supply crate (Waldo_fnc_SupplyCratePopulate) scoped to the servicing hub's
        // side, so these mirror that function's own parameters rather than a separate charge model.
        ["Waldo_FieldResupply_Enable", true],       // BOOL: enables service/actions; hubs/carriers still need registration.
        ["Waldo_FieldResupply_CrateClass", "Box_NATO_Ammo_F"], // CfgVehicles class for the deployed physical crate.
        ["Waldo_FieldResupply_DefaultCarrierCapacity", 2], // CRATES: default assigned player carrying capacity.
        ["Waldo_FieldResupply_CrateSizeScalar", 1], // SCALAR: multiplies populated magazine/item/weapon quantities.
        ["Waldo_FieldResupply_IncludeWeaponsAttachments", false], // BOOL: also populate weapons, attachments, clothing and gear, not just ammunition.
        ["Waldo_FieldResupply_IncludeLaunchers", false], // BOOL: also populate launchers and launcher ammunition.
        ["Waldo_FieldResupply_RetainOnRespawn", true], // BOOL: retain assigned carrier status/count after respawn.
        // ADVANCED recovery cadence/placement followed by MISSION MAKER presentation/content.
        ["Waldo_Recovery_ScanInterval", 3],            // Seconds; lower values increase server scans.
        ["Waldo_Recovery_NotificationRadius", 100], // METRES: audience around workshop for completed recovery.
        ["Waldo_Recovery_CreateWorkshopMarkers", true], // BOOL: area and exact-position markers per workshop.
        ["Waldo_Recovery_PlacementClearance", 3],   // METRES: extra clear footprint required for restoration.
        ["Waldo_Recovery_DefaultCustomVariables", ["Waldo_TransportService_Registration"]], // ARRAY of serialisable variable-name strings copied for every vehicle. This built-in row preserves transport-service setup when recovery rebuilds a vehicle.
        ["Waldo_Recovery_PackageClasses", ["B_Slingload_01_Cargo_F", "Land_Pallet_MilBoxes_F"]] // ordered valid package object classes.
    ]],
    ["server", [
        // MISSION MAKER service defaults; registering a vehicle still remains a separate explicit call.
        ["Waldo_TransportServices_Enable", true, true], // BOOL: enables inert shared service framework.
        ["Waldo_Transport_TravelTimeout", 900, false], // SECONDS: one physical movement deadline.
        ["Waldo_Transport_DefaultBoardingSeconds", 300, false], // SECONDS: pickup boarding window.
        ["Waldo_Transport_DefaultDestinationDwell", 45, false], // SECONDS: when forceDisembark may request exit. RTB still waits until no human occupies any seat.
        ["Waldo_Transport_DestinationSettleSeconds", 3, false], // ADVANCED SECONDS: continuous ground contact/low speed required before automatic RTB.
        ["Waldo_Transport_DestinationEmptyConfirmSeconds", 2, false], // ADVANCED SECONDS: continuous fullCrew human-empty confirmation required before automatic RTB.
        ["Waldo_Transport_DestinationSettleSpeedKph", 5, false], // ADVANCED KM/H: maximum total vehicle speed counted as settled at destination.
        ["Waldo_HeliTransport_DefaultAltitude", 50, false], // METRES: default helicopter transit height.
        ["Waldo_HeliTransport_DefaultLzSearchRadius", 500, false], // METRES: maximum permitted LZ adjustment from the click.
        ["Waldo_HeliTransport_DefaultLzClearanceScale", 1.5, false], // MULTIPLIER: expand both model axes; the longer expanded half-axis becomes the circular LZ clearance.
        ["Waldo_HeliTransport_DefaultSeparation", 60, false], // METRES: space helicopter bases/LZs apart to reduce rotor and landing conflicts.
        ["Waldo_GroundTransport_DefaultRoadSearchRadius", 200, false], // METRES: nearest-road search around pickup/destination.
        ["Waldo_GroundTransport_DefaultSeparation", 18, false], // METRES: space vehicle bases/stops apart to reduce blocking and collisions.
        ["Waldo_GroundTransport_DefaultSpeedLimit", 60, false], // KM/H: road-safe AI transport speed cap.
        ["Waldo_BoatTransport_DefaultWaterSearchRadius", 300, false], // METRES: nearest-open-water search around a pickup/destination click.
        ["Waldo_BoatTransport_DefaultSeparation", 25, false], // METRES: space boat bases/stops apart to reduce blocking and collisions.
        ["Waldo_BoatTransport_DefaultSpeedLimit", 45, false], // KM/H: AI boat transport speed cap.
        ["Waldo_Transport_DefaultPathRetrySeconds", 25, false], // SECONDS without progress before reissuing an order.
        ["Waldo_Transport_DefaultPathRetryLimit", 3, false], // COUNT: automatic ground path retries per journey.
        ["Waldo_Transport_MaxEffectiveDamage", 0.8, false], // FRACTION 0-1: at/above this, a still-"alive" transport is written off like a loss.
        // MISSION MAKER scale bounds; ADVANCED client-authority switch.
        ["Waldo_ObjectScaling_Minimum", 0.1, false],   // Positive scale multiplier.
        ["Waldo_ObjectScaling_Maximum", 10, false], // Positive scale multiplier; must be >= Minimum.
        ["Waldo_ObjectScaling_AllowClientRequests", false, false], // BOOL: normally false; ZEN/server remains authority.
        ["Logi_SupplyBoxClass", "B_supplyCrate_F", true] // MISSION MAKER: spawned supply crate classname.
    ]],
    ["conditional", [
        // ADVANCED: automatic ACE/fallback medical crate selection; edit only for a deliberate override.
        ["SERVER", "Logi_MedicalBoxClass", "ace_medical", "ACE_medicalSupplyCrate_advanced", "C_IDAP_supplyCrate_F", true]
    ]]
]

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
 * Magazine allow/block arrays contain magazine classnames; an empty allowlist permits discovered
 * compatible magazines. Recovery custom variables use the documented serialisable variable schema.
 * ADVANCED TUNING - capacity-band amounts, minimum rounds, recovery scan interval/clearance and
 * client scale requests affect balance, traffic or placement safety. Intervals are seconds,
 * radii/clearance are metres and object scale is a positive multiplier. Client scale requests should
 * normally remain false. Medical crate selection is dependency-sensitive and normally automatic.
 *
 * HOW TO READ THE DATA BELOW:
 * `shared` rows are `[variable, default]`. `server` rows are `[variable, default, publish]` where
 * publish true sends the authoritative value to clients/JIP. `conditional` rows are
 * `[scope, variable, required CfgPatches class, value when present, value when absent, publish]`.
 * None of these rows creates a hub, carrier, workshop or crate by itself.
 * CapacityAmounts is ordered by magazine capacity: `[1-4 rounds, 5-10, 11-40, 41-70, 71+]`.
 * Recovery DefaultCustomVariables is an ARRAY of variable-name STRINGs; only serialisable values
 * are copied into a vehicle package. PackageClasses is an ordered fallback pool of CfgVehicles
 * classes and may be overridden per registered vehicle.
 *
 * SETTING-BY-SETTING GUIDE - FIELD RESUPPLY:
 * - Waldo_FieldResupply_Enable (MISSION MAKER): permits hubs/actions; register a hub and assign carriers separately.
 * - Waldo_FieldResupply_CrateClass (MISSION MAKER): valid CfgVehicles crate spawned empty for each deployment.
 * - Waldo_FieldResupply_DefaultCarrierCapacity (MISSION MAKER): logical crates granted to a newly assigned carrier.
 * - Waldo_FieldResupply_ChargesPerCrate (MISSION MAKER): resupply transactions available from one deployed crate.
 * - Waldo_FieldResupply_MagazinesPerType (MISSION MAKER): flat quantity per compatible type when capacity mode is off.
 * - Waldo_FieldResupply_UseCapacityBasedAmounts (MISSION MAKER): true uses the five capacity bands below.
 * - Waldo_FieldResupply_CapacityAmounts (MISSION MAKER): five issued quantities for 1-4, 5-10, 11-40, 41-70, 71+ rounds.
 * - Waldo_FieldResupply_MinimumMagazineRounds (MISSION MAKER): lower-capacity magazines are excluded automatically.
 * - Waldo_FieldResupply_AllowedMagazines (MISSION MAKER): [] discovers compatible carried types; otherwise exact allowlist.
 * - Waldo_FieldResupply_BlockedMagazines (MISSION MAKER): exact deny list, applied after and overriding the allowlist.
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
 * - Waldo_TransportServices_Enable: permits registered helicopter and ground taxi services; creates none.
 * - Waldo_Transport_TravelTimeout: maximum seconds allowed for one physical journey before failure recovery.
 * - Waldo_Transport_DefaultBoardingSeconds: maximum pickup wait before an unused service returns to base.
 * - Waldo_Transport_DefaultDestinationDwell: maximum destination wait before physical RTB begins.
 * - Waldo_HeliTransport_DefaultAltitude: default transit height in metres for registered helicopters.
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
    ["featureFamilies", ["Field Resupply", "Vehicle Recovery", "Helicopter Transport", "Ground Taxi", "Object Scaling", "Logistics Crates"]],
    ["shared", [
        // MISSION MAKER: field-resupply content and balance.
        ["Waldo_FieldResupply_Enable", false],       // BOOL: enables service/actions; hubs/carriers still need registration.
        ["Waldo_FieldResupply_CrateClass", "Box_NATO_Ammo_F"], // CfgVehicles class for deployed empty physical crate.
        ["Waldo_FieldResupply_DefaultCarrierCapacity", 2], // CRATES: default assigned player carrying capacity.
        ["Waldo_FieldResupply_ChargesPerCrate", 5], // USES: logical resupply transactions before crate empties.
        ["Waldo_FieldResupply_MagazinesPerType", 1], // COUNT issued per compatible type when capacity mode is false.
        ["Waldo_FieldResupply_UseCapacityBasedAmounts", true], // ADVANCED: false uses MagazinesPerType for every type.
        ["Waldo_FieldResupply_CapacityAmounts", [
            4, // magazines issued when each magazine holds 1-4 rounds.
            3, // magazines issued when each magazine holds 5-10 rounds.
            8, // magazines issued when each magazine holds 11-40 rounds.
            3, // magazines issued when each magazine holds 41-70 rounds.
            2  // magazines issued when each magazine holds 71 or more rounds.
        ]],
        ["Waldo_FieldResupply_MinimumMagazineRounds", 2], // ROUNDS: excludes grenades/single-round ordnance by default.
        ["Waldo_FieldResupply_AllowedMagazines", []], // ARRAY of exact magazine classes; [] discovers carried types.
        ["Waldo_FieldResupply_BlockedMagazines", []], // ARRAY of exact classes always excluded; wins over allowlist.
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
        ["Waldo_Transport_DefaultDestinationDwell", 45, false], // SECONDS: destination disembark window.
        ["Waldo_HeliTransport_DefaultAltitude", 80, false], // METRES: default helicopter transit height.
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

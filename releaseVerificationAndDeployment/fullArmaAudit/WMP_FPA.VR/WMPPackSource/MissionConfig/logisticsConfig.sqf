/*
 * Author: WaldoTheWarfighter
 * Defines field-resupply, vehicle-recovery, object-scaling and logistics-crate defaults. World
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
 */
createHashMapFromArray [
    ["featureFamilies", ["Field Resupply", "Vehicle Recovery", "Object Scaling", "Logistics Crates"]],
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
        ["Waldo_Recovery_DefaultCustomVariables", []], // ARRAY of serialisable variable-name strings copied for every vehicle.
        ["Waldo_Recovery_PackageClasses", ["B_Slingload_01_Cargo_F", "Land_Pallet_MilBoxes_F"]] // ordered valid package object classes.
    ]],
    ["server", [
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

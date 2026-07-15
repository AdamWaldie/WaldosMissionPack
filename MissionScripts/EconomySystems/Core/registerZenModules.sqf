/*
 * Author: Waldo
 * Register zen modules.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Registers every Economy Systems action as a Zeus Enhanced custom module under the
 * "Waldos Economy Systems" category. This is the supported replacement for the previous
 * raw curator-tree injection: ZEN owns the module list, so there is no per-client polling
 * loop and no dependency on undocumented curator display IDCs. Requires Zeus Enhanced -
 * without it the suite still runs server-side (income, research, production, requests) but
 * exposes no Zeus authoring menu.
 *
 * ZEN passes each module's code [_modulePos (ASL), _attachedObject] on the curator's
 * client. Every module first runs Waldo_fnc_EcoCore_zenModuleGuard so a purged / inactive
 * economy no-ops instead of acting (ZEN cannot un-register modules mid-mission). Placement
 * actions convert the drop position via Waldo_fnc_EcoCore_zenPlacementPos and hand it to the
 * existing spawn / prompt handlers; those spawn functions forward themselves to the server
 * authority, so placement works on dedicated servers. Non-placement actions ignore the
 * position and open their existing dialog / toggle.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_registerZenModules;
 */

    if (!hasInterface) exitWith {};
    if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};
    if (!isNil "WaldoEcoCore_ZenModulesRegistered") exitWith {};
    WaldoEcoCore_ZenModulesRegistered = true;

    private _cat = "Waldos Economy Systems";
    private _icon = "\a3\modules_f\data\portraitmodule_ca.paa";

    // ---- Resource ----
    [_cat, "Resource - Configure Resources",
        {
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoResource_promptResourceConfig;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Resource - Create Resource Crate",
        {
            params ["_modulePos"];
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [[_modulePos] call Waldo_fnc_EcoCore_zenPlacementPos] call Waldo_fnc_EcoResource_promptResourceCrateValue;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Resource - Create Resource Zone",
        {
            params ["_modulePos"];
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [[_modulePos] call Waldo_fnc_EcoCore_zenPlacementPos] call Waldo_fnc_EcoResource_promptResourceZone;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Resource - Set Resources",
        {
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoResource_promptResourceSettings;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Resource - Toggle Resource Visibility",
        {
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [name player] call Waldo_fnc_EcoResource_toggleResourceMarkerVisibility;
        },
    _icon] call zen_custom_modules_fnc_register;

    // ---- Research ----
    [_cat, "Research - Configure Research",
        {
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoResearch_promptResearchConfig;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Research - Create Research Center",
        {
            params ["_modulePos"];
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [[_modulePos] call Waldo_fnc_EcoCore_zenPlacementPos] call Waldo_fnc_EcoResearch_spawnResearchCenter;
        },
    _icon] call zen_custom_modules_fnc_register;

    // ---- Construction (Build) ----
    [_cat, "Construction - Configure Buildables",
        {
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoBuild_promptBuildConfig;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Construction - Spawn Building",
        {
            params ["_modulePos"];
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [[_modulePos] call Waldo_fnc_EcoCore_zenPlacementPos] call Waldo_fnc_EcoBuild_promptSpawnBuilding;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Construction - Spawn Construction Vehicle",
        {
            params ["_modulePos"];
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [[_modulePos] call Waldo_fnc_EcoCore_zenPlacementPos, "B_Truck_01_box_F"] call Waldo_fnc_EcoBuild_spawnConstructionVehicle;
        },
    _icon] call zen_custom_modules_fnc_register;

    // ---- Buy ----
    [_cat, "Buy - Configure Purchases",
        {
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoBuy_promptPurchaseConfig;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Buy - Set Drop Point",
        {
            params ["_modulePos"];
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [[_modulePos] call Waldo_fnc_EcoCore_zenPlacementPos, getDir curatorCamera] call Waldo_fnc_EcoBuy_promptDropPoint;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Buy - Spawn Laptop",
        {
            params ["_modulePos"];
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [[_modulePos] call Waldo_fnc_EcoCore_zenPlacementPos, getDir curatorCamera] call Waldo_fnc_EcoBuy_spawnPurchaseLaptop;
        },
    _icon] call zen_custom_modules_fnc_register;

    // ---- Ground Command ----
    [_cat, "Ground Command",
        {
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoCommand_promptGroundCommand;
        },
    _icon] call zen_custom_modules_fnc_register;

    // ---- Core / Save ----
    [_cat, "Toggle Commitment Mode",
        {
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoCore_toggleCommitmentMode;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Toggle Testing Notice",
        {
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoCore_toggleTestingNotice;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Import / Export",
        {
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoCore_promptUnifiedSaveSystem;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Preset Configurations",
        {
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoCore_promptUnifiedPresetSystem;
        },
    _icon] call zen_custom_modules_fnc_register;

    // Purge intentionally omits the active-guard: it must remain usable to confirm/clear a
    // suite that is being torn down.
    [_cat, "Purge System",
        { [] call Waldo_fnc_EcoCore_promptUnifiedPurgeSystem; },
    _icon] call zen_custom_modules_fnc_register;

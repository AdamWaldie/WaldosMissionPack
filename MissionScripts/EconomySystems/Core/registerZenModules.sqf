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
 * client. Placement actions convert the drop position to AGL and hand it to the existing
 * spawn / prompt handlers; those spawn functions forward themselves to the server
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
        { [] call Waldo_fnc_EcoResource_promptResourceConfig; },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Resource - Create Resource Crate",
        {
            params ["_modulePos"];
            [ASLToAGL _modulePos] call Waldo_fnc_EcoResource_promptResourceCrateValue;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Resource - Create Resource Zone",
        {
            params ["_modulePos"];
            [ASLToAGL _modulePos] call Waldo_fnc_EcoResource_promptResourceZone;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Resource - Set Resources",
        { [] call Waldo_fnc_EcoResource_promptResourceSettings; },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Resource - Toggle Resource Visibility",
        { [name player] call Waldo_fnc_EcoResource_toggleResourceMarkerVisibility; },
    _icon] call zen_custom_modules_fnc_register;

    // ---- Research ----
    [_cat, "Research - Configure Research",
        { [] call Waldo_fnc_EcoResearch_promptResearchConfig; },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Research - Create Research Center",
        {
            params ["_modulePos"];
            [ASLToAGL _modulePos] call Waldo_fnc_EcoResearch_spawnResearchCenter;
        },
    _icon] call zen_custom_modules_fnc_register;

    // ---- Construction (Build) ----
    [_cat, "Construction - Configure Buildables",
        { [] call Waldo_fnc_EcoBuild_promptBuildConfig; },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Construction - Spawn Building",
        {
            params ["_modulePos"];
            [ASLToAGL _modulePos] call Waldo_fnc_EcoBuild_promptSpawnBuilding;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Construction - Spawn Construction Vehicle",
        {
            params ["_modulePos"];
            [ASLToAGL _modulePos, "B_Truck_01_box_F"] call Waldo_fnc_EcoBuild_spawnConstructionVehicle;
        },
    _icon] call zen_custom_modules_fnc_register;

    // ---- Buy ----
    [_cat, "Buy - Configure Purchases",
        { [] call Waldo_fnc_EcoBuy_promptPurchaseConfig; },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Buy - Set Drop Point",
        {
            params ["_modulePos"];
            [ASLToAGL _modulePos, getDir curatorCamera] call Waldo_fnc_EcoBuy_promptDropPoint;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Buy - Spawn Laptop",
        {
            params ["_modulePos"];
            [ASLToAGL _modulePos, getDir curatorCamera] call Waldo_fnc_EcoBuy_spawnPurchaseLaptop;
        },
    _icon] call zen_custom_modules_fnc_register;

    // ---- Ground Command ----
    [_cat, "Ground Command",
        { [] call Waldo_fnc_EcoCommand_promptGroundCommand; },
    _icon] call zen_custom_modules_fnc_register;

    // ---- Core / Save ----
    [_cat, "Commitment Mode",
        { [] call Waldo_fnc_EcoCore_toggleCommitmentMode; },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Testing Notice",
        { [] call Waldo_fnc_EcoCore_toggleTestingNotice; },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Import / Export",
        { [] call Waldo_fnc_EcoCore_promptUnifiedSaveSystem; },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Preset Configurations",
        { [] call Waldo_fnc_EcoCore_promptUnifiedPresetSystem; },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Purge System",
        { [] call Waldo_fnc_EcoCore_promptUnifiedPurgeSystem; },
    _icon] call zen_custom_modules_fnc_register;

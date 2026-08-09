/*
 * Author: WaldoTheWarfighter
 * Registers every WMP Economy Systems control as a Zeus Enhanced custom module.
 *
 * Registers every Economy Systems action as a Zeus Enhanced custom module under the
 * "WMP Economy Systems" category. This is the supported replacement for the previous
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
 * Locality and authority:
 * Runs on interface clients only. Dialogs run on the curator client; authoritative changes are
 * forwarded by the existing handlers to the server. ZEN registrations are local UI state.
 *
 * Repeat / JIP Behaviour:
 * Repeat-safe through WaldoEcoCore_ZenModulesRegistered. Every JIP curator registers the module
 * catalogue when their local economy client lifecycle starts.
 *
 * Arguments:
 * None.
 *
 * Return Value:
 * Nothing.
 *
 * Current Callers:
 * Waldo_fnc_EcoInit after the shared economy display/category defaults have been defined.
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_registerZenModules;
 * Result: this curator client receives one WMP Economy Systems ZEN catalogue.
 */

    if (!hasInterface) exitWith {};
    if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};
    if (!isNil "WaldoEcoCore_ZenModulesRegistered") exitWith {};
    WaldoEcoCore_ZenModulesRegistered = true;

    private _cat = missionNamespace getVariable ["WaldoEcoCore_ZeusHeaderRootText", "WMP Economy Systems"];
    private _icon = "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa";

    // ---- Resource ----
    [_cat, "Resource: Define Resource Types",
        {
            ["Resource - Configure Resources", _this] call Waldo_fnc_EcoCore_logZenModule;
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoResource_promptResourceConfig;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Resource: Place Collectible Crate",
        {
            ["Resource - Create Resource Crate", _this] call Waldo_fnc_EcoCore_logZenModule;
            params ["_modulePos"];
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [[_modulePos] call Waldo_fnc_EcoCore_zenPlacementPos] call Waldo_fnc_EcoResource_promptResourceCrateValue;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Resource: Place Production Zone",
        {
            ["Resource - Create Resource Zone", _this] call Waldo_fnc_EcoCore_logZenModule;
            params ["_modulePos"];
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [[_modulePos] call Waldo_fnc_EcoCore_zenPlacementPos] call Waldo_fnc_EcoResource_promptResourceZone;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Resource: Set Side Balances",
        {
            ["Resource - Set Resources", _this] call Waldo_fnc_EcoCore_logZenModule;
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoResource_promptResourceSettings;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Resource: Toggle Map Visibility",
        {
            ["Resource - Toggle Resource Visibility", _this] call Waldo_fnc_EcoCore_logZenModule;
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            ["TOGGLE_MARKERS", [name player], player] remoteExecCall ["Waldo_fnc_EcoCore_zenServerRequest", 2];
        },
    _icon] call zen_custom_modules_fnc_register;

    // ---- Research ----
    _icon = "\a3\ui_f\data\igui\cfg\simpletasks\types\download_ca.paa";
    [_cat, "Research: Define Technology Tree",
        {
            ["Research - Configure Research", _this] call Waldo_fnc_EcoCore_logZenModule;
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoResearch_promptResearchConfig;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Research: Place Research Centre",
        {
            ["Research - Create Research Center", _this] call Waldo_fnc_EcoCore_logZenModule;
            params ["_modulePos"];
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            ["SPAWN_RESEARCH_CENTER", [[_modulePos] call Waldo_fnc_EcoCore_zenPlacementPos], player]
                remoteExecCall ["Waldo_fnc_EcoCore_zenServerRequest", 2];
        },
    _icon] call zen_custom_modules_fnc_register;

    // ---- Construction (Build) ----
    _icon = "\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\repair_ca.paa";
    [_cat, "Construction: Define Build Catalogue",
        {
            ["Construction - Configure Buildables", _this] call Waldo_fnc_EcoCore_logZenModule;
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoBuild_promptBuildConfig;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Construction: Place Completed Building",
        {
            ["Construction - Spawn Building", _this] call Waldo_fnc_EcoCore_logZenModule;
            params ["_modulePos"];
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [[_modulePos] call Waldo_fnc_EcoCore_zenPlacementPos] call Waldo_fnc_EcoBuild_promptSpawnBuilding;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Construction: Place Consumable Build Vehicle",
        {
            ["Construction - Spawn Construction Vehicle", _this] call Waldo_fnc_EcoCore_logZenModule;
            params ["_modulePos"];
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            ["SPAWN_CONSTRUCTION_VEHICLE", [[_modulePos] call Waldo_fnc_EcoCore_zenPlacementPos, "B_Truck_01_box_F"], player]
                remoteExecCall ["Waldo_fnc_EcoCore_zenServerRequest", 2];
        },
    _icon] call zen_custom_modules_fnc_register;

    // ---- Buy ----
    _icon = "\A3\ui_f\data\map\vehicleicons\iconCar_ca.paa";
    [_cat, "Purchasing: Define Vehicle Catalogue",
        {
            ["Buy - Configure Purchases", _this] call Waldo_fnc_EcoCore_logZenModule;
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoBuy_promptPurchaseConfig;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Purchasing: Place Delivery Point",
        {
            ["Buy - Set Drop Point", _this] call Waldo_fnc_EcoCore_logZenModule;
            params ["_modulePos"];
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [[_modulePos] call Waldo_fnc_EcoCore_zenPlacementPos, getDir curatorCamera] call Waldo_fnc_EcoBuy_promptDropPoint;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Purchasing: Place Player Terminal",
        {
            ["Buy - Spawn Laptop", _this] call Waldo_fnc_EcoCore_logZenModule;
            params ["_modulePos"];
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            ["SPAWN_PURCHASE_LAPTOP", [[_modulePos] call Waldo_fnc_EcoCore_zenPlacementPos, getDir curatorCamera], player]
                remoteExecCall ["Waldo_fnc_EcoCore_zenServerRequest", 2];
        },
    _icon] call zen_custom_modules_fnc_register;

    // ---- Ground Command ----
    _icon = "\a3\ui_f\data\igui\cfg\simpletasks\types\attack_ca.paa";
    [_cat, "Authority: Assign Ground Command",
        {
            ["Ground Command", _this] call Waldo_fnc_EcoCore_logZenModule;
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoCommand_promptGroundCommand;
        },
    _icon] call zen_custom_modules_fnc_register;

    // ---- Core / Save ----
    _icon = "\a3\ui_f\data\igui\cfg\simpletasks\types\interact_ca.paa";
    [_cat, "Rules: Toggle Commitment Mode",
        {
            ["Toggle Commitment Mode", _this] call Waldo_fnc_EcoCore_logZenModule;
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            ["SET_COMMITMENT", [!([] call Waldo_fnc_EcoCore_isCommitmentModeEnabled), true, player], player]
                remoteExecCall ["Waldo_fnc_EcoCore_zenServerRequest", 2];
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Diagnostics: Toggle Test Notices",
        {
            ["Toggle Testing Notice", _this] call Waldo_fnc_EcoCore_logZenModule;
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            ["SET_TEST_NOTICE", [!([] call Waldo_fnc_EcoCore_isTestingNoticeEnabled), true, player], player]
                remoteExecCall ["Waldo_fnc_EcoCore_zenServerRequest", 2];
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Configuration: Build Mission Setup",
        {
            ["Build Mission Setup", _this] call Waldo_fnc_EcoCore_logZenModule;
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoCore_promptUnifiedSaveSystem;
        },
    _icon] call zen_custom_modules_fnc_register;

    [_cat, "Configuration: Apply Preset",
        {
            ["Preset Configurations", _this] call Waldo_fnc_EcoCore_logZenModule;
            if !(call Waldo_fnc_EcoCore_zenModuleGuard) exitWith {};
            [] call Waldo_fnc_EcoCore_promptUnifiedPresetSystem;
        },
    _icon] call zen_custom_modules_fnc_register;

    // Purge intentionally omits the active-guard: it must remain usable to confirm/clear a
    // suite that is being torn down.
    [_cat, "Danger: Purge Economy System",
        {
            ["Purge System", _this] call Waldo_fnc_EcoCore_logZenModule;
            [] call Waldo_fnc_EcoCore_promptUnifiedPurgeSystem;
        },
    _icon] call zen_custom_modules_fnc_register;

    missionNamespace setVariable ["WaldoEcoCore_ZenModuleCount", 19];
    diag_log format ["[WMP ECO ZEN] Registered 19 Economy modules on clientOwner=%1", clientOwner];

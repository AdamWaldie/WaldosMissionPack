/*
 * Author: WaldoTheWarfighter
 * Registers WMP's Zeus Enhanced modules in task-oriented categories. Combat/AI generation,
 * electronic warfare, environmental hazards, air operations, transport, logistics, mission flow,
 * mission tools and interface/QA are separated so curators can find a control by purpose.
 *
 * Locality and repeat/JIP behaviour:
 * Player-interface only. Every curator client (including JIP) registers its own local palette after
 * ZEN is available. A missionNamespace guard prevents duplicate registration on the same machine.
 * Module effects retain their documented server/object-owner authority; this file only creates UI.
 *
 * Arguments: None.
 * Return Value: Nothing.
 *
 * Example: [] call Waldo_fnc_ZenInitModules;
 * Current caller: initPlayerLocal.sqf after local player and ZEN readiness.
*/

// Registration creates local curator UI entries; servers and headless clients have no consumer.
if !(hasInterface) exitWith {};

//Check for, and exit if not present: Zeus Enhanced
if !(isClass(configFile >> "CfgPatches" >> "zen_main")) exitWith {};
if (missionNamespace getVariable ["Waldo_ZenModulesRegistered", false]) exitWith {
    diag_log format ["[WMP ZEN] Core module registration already complete on clientOwner=%1", clientOwner];
};
missionNamespace setVariable ["Waldo_ZenModulesRegistered", true];


//Add ZEN modules
["WMP Logistics", "Supplies: Create Player Crate",
    {
        diag_log format ["[WMP ZEN] invoked module=Player Supply Crate curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call Waldo_fnc_ZenSupplySpawner;
    },
    "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP AI & Combat", "Dynamic AA - Create",
    {
        params ["_modulePos"];
        [_modulePos] call Waldo_fnc_DynamicAAZen;
    },
    "\A3\ui_f\data\map\vehicleicons\iconStaticAA_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP AI & Combat", "Dynamic AA - Remove Nearest",
    {
        params ["_modulePos"];
        [_modulePos] call Waldo_fnc_DynamicAARemoveZen;
    },
    "\A3\ui_f\data\map\markers\nato\o_antiair.paa"
] call zen_custom_modules_fnc_register;

["WMP Vehicle Customisation", "Vehicle Customisation - Editor",
    {
        params ["_modulePos", ["_objectPos", objNull]];
        [_modulePos, _objectPos] call Waldo_fnc_ZenVehicleCustomizationEditor;
    },
    "\A3\ui_f\data\igui\cfg\actions\reammo_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Vehicle Customisation", "Vehicle Customisation - Inspect",
    {
        params ["_modulePos", ["_objectPos", objNull]];
        [_modulePos, _objectPos] call Waldo_fnc_ZenVehicleCustomizationInspect;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\intel_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Mission Tools", "Scale Object",
    {
        params ["_modulePos", ["_objectPos", objNull]];
        [_modulePos, _objectPos] call Waldo_fnc_ObjectScaleZen;
    },
    "\A3\ui_f\data\igui\cfg\actions\reammo_ca.paa"
] call zen_custom_modules_fnc_register;

{
    _x params ["_category", "_name", "_feature", "_icon"];
    private _handler = compile format [
        "params ['_modulePos', ['_objectPos', objNull]]; ['%1', _modulePos, _objectPos] call Waldo_fnc_FeatureRuntimeZen;",
        _feature
    ];
    [_category, _name,
        _handler,
        _icon
    ] call zen_custom_modules_fnc_register;
} forEach [
    ["WMP Mission Tools", "Persistence - Control", "PERSISTENCE", "\A3\ui_f\data\igui\cfg\simpletasks\types\download_ca.paa"],
    ["WMP Mission Tools", "Persistence - Register Object", "PERSISTENCE_OBJECT", "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"],
    ["WMP Mission Tools", "Persistence - Save Now", "PERSISTENCE_SAVE", "\A3\ui_f\data\igui\cfg\simpletasks\types\download_ca.paa"],
    ["WMP Logistics", "Field Resupply - Register Hub", "FIELD_RESUPPLY_HUB", "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"],
    ["WMP Logistics", "Field Resupply - Assign Carrier", "FIELD_RESUPPLY_CARRIER", "\A3\ui_f\data\map\vehicleicons\iconMan_ca.paa"],
    ["WMP Logistics", "Field Resupply - Grant Crates", "FIELD_RESUPPLY_GRANT", "\A3\ui_f\data\igui\cfg\simpletasks\types\rearm_ca.paa"],
    ["WMP Logistics", "Vehicle Recovery - Register Workshop", "RECOVERY_WORKSHOP", "\A3\ui_f\data\igui\cfg\actions\repair_ca.paa"],
    ["WMP Logistics", "Vehicle Recovery - Register Vehicle", "RECOVERY_VEHICLE", "\A3\ui_f\data\map\vehicleicons\iconCar_ca.paa"],
    ["WMP Logistics", "Vehicle Recovery - Register Carrier", "RECOVERY_CARRIER", "\A3\ui_f\data\map\vehicleicons\iconTruck_ca.paa"],
    ["WMP Transport", "Transport Service - Register", "TRANSPORT_REGISTER", "\A3\ui_f\data\map\vehicleicons\iconCar_ca.paa"],
    ["WMP Transport", "Transport Service - Return to Base", "TRANSPORT_RTB", "\A3\ui_f\data\igui\cfg\simpletasks\types\meet_ca.paa"],
    ["WMP Mission Flow", "Respawn - Squad Rally Control", "RALLY", "\A3\ui_f\data\map\markers\military\start_CA.paa"],
    ["WMP Interface & QA", "Tactical Display - Register", "TACTICAL_DISPLAY", "\A3\ui_f\data\igui\cfg\simpletasks\types\map_ca.paa"],
    ["WMP Air Operations", "Gunship - Register or Spawn", "GUNSHIP_REGISTER", "\A3\ui_f\data\map\vehicleicons\iconPlane_ca.paa"],
    ["WMP Air Operations", "Gunship - Assign Controller", "GUNSHIP_ASSIGN", "\A3\ui_f\data\igui\cfg\actions\getincommander_ca.paa"],
    ["WMP Air Operations", "Gunship - Set Orbit", "GUNSHIP_ORBIT", "\A3\ui_f\data\igui\cfg\simpletasks\types\map_ca.paa"],
    ["WMP Air Operations", "Gunship - Operational Control", "GUNSHIP_CONTROL", "\A3\ui_f\data\igui\cfg\simpletasks\types\plane_ca.paa"],
    ["WMP AI & Combat", "AI Rebalance - Control", "AI", "\A3\ui_f\data\map\vehicleicons\iconMan_ca.paa"]
];

["WMP Mission Tools", "Create Custom 3D Marker",
    {params ["_modulePos", ["_objectPos", objNull]]; [_modulePos, _objectPos] call Waldo_fnc_ZenCreate3DMarker;},
    "\A3\ui_f\data\map\markers\military\dot_CA.paa"
] call zen_custom_modules_fnc_register;

["WMP Mission Tools", "Add WMP Field Equipment Interaction",
    {params ["_modulePos", ["_objectPos", objNull]]; [_modulePos, _objectPos] call Waldo_fnc_ZenFieldEquipment;},
    "\A3\ui_f\data\IGUI\Cfg\simpleTasks\types\interact_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Air Operations", "Paradrop - Create Drop Zone",
    {params ["_modulePos"]; ["CREATE", _modulePos] call Waldo_fnc_ParadropDropZoneZen;},
    "\A3\ui_f\data\map\vehicleicons\iconPlane_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP AI & Combat", "Dynamic AO - Create",
    {
        params ["_modulePos"];
        [_modulePos] call Waldo_fnc_DynamicAOZen;
    },
    "\A3\ui_f\data\map\markers\nato\o_inf.paa"
] call zen_custom_modules_fnc_register;

["WMP AI & Combat", "Dynamic AO - Remove",
    {
        params ["_modulePos"];
        [_modulePos] call Waldo_fnc_DynamicAORemoveZen;
    },
    "\A3\ui_f\data\map\markers\military\destroy_CA.paa"
] call zen_custom_modules_fnc_register;

["WMP Air Operations", "Paradrop - Embark Players",
    {params ["_modulePos", ["_objectPos", objNull]]; ["EMBARK", _modulePos, _objectPos] call Waldo_fnc_ParadropDropZoneZen;},
    "\A3\ui_f\data\igui\cfg\actions\getincargo_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Air Operations", "Paradrop - Remove Operation",
    {params ["_modulePos"]; ["REMOVE", _modulePos] call Waldo_fnc_ParadropDropZoneZen;},
    "\A3\ui_f\data\map\markers\military\end_CA.paa"
] call zen_custom_modules_fnc_register;

["WMP Interface & QA", "UI QA - Set Visual Theme",
    {[] call Waldo_fnc_UiThemeZen;},
    "\A3\ui_f\data\igui\cfg\simpletasks\types\whiteboard_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Mission Flow", "Mission Flow: End Mission + Show AAR",
    {
        diag_log format ["[WMP ZEN] invoked module=Call Endex curator=%1 payload=%2", name player, _this];
        [] remoteExecCall ["Waldo_fnc_ENDEX", 2];
    },
    "\a3\modules_f\data\portraitmodule_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Mission Flow", "Mission Flow: End Mission (No AAR)",
    {
        diag_log format ["[WMP ZEN] invoked module=Custom Mission End curator=%1 payload=%2", name player, _this];
        ["end1"] remoteExec ["BIS_fnc_endMission",0,true];
    },
    "\a3\Missions_F_Orange\Data\Img\Showcase_LawsOfWar\action_end_sim_CA.paa"
] call zen_custom_modules_fnc_register;

["WMP Mission Flow", "Mission Flow: Send Notification",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call Waldo_fnc_ZenNotify;
    },
    "\A3\ui_f\data\igui\cfg\simpletasks\types\Radio_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Logistics", "Medical: Create Field Hospital Crate",
    {
        diag_log format ["[WMP ZEN] invoked module=Field Hospital Crate curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos,1] call Waldo_fnc_ZenMedicalSpawner;
    },
    "\z\ACE\addons\medical_gui\ui\cross.paa"
] call zen_custom_modules_fnc_register;

["WMP Logistics", "Fortify: Set Side Budget",

    {
        diag_log format ["[WMP ZEN] invoked module=Fortify Budget Manager curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [] call Waldo_fnc_FortifyBudgetModule;
    },
    "\z\ACE\addons\fortify\ui\hammer_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP AI & Combat", "Convoy - Create Moving Group",
    {
        diag_log format ["[WMP ZEN] invoked module=Spawn AI Convoy curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos] call Waldo_fnc_ZenConvoyModule;
    },
    "\A3\ui_f\data\map\vehicleicons\iconTruck_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Logistics", "Respawn: Create Loadout Save Point",
    {
        diag_log format ["[WMP ZEN] invoked module=Loadout Save Point curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos, player] call Waldo_fnc_ZenLoadoutSaveModule;
    },
    "\A3\ui_f\data\map\vehicleicons\iconMan_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Mission Flow", "SafeStart: Enable Protection",
    {
        diag_log format ["[WMP ZEN] invoked module=Safestart Activate curator=%1", name player];
        [true] remoteExec ["Waldo_fnc_SafeStart", 2];
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\interact_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Mission Flow", "SafeStart: Go Live Now",
    {
        diag_log format ["[WMP ZEN] invoked module=Safestart Go Live curator=%1", name player];
        [false] remoteExec ["Waldo_fnc_SafeStart", 2];
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\attack_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Mission Flow", "SafeStart: Start Go-Live Timer",
    {
        diag_log format ["[WMP ZEN] invoked module=Safestart Countdown curator=%1", name player];
        [] call Waldo_fnc_ZenSafeStartTimer;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\download_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Electronic Warfare", "Jammer - Place Emitter",
    {
        diag_log format ["[WMP ZEN] invoked module=Radio Jammer Place curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call Waldo_fnc_ZenJammerPlace;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\interact_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Electronic Warfare", "Jammer - Toggle Nearest",
    {
        diag_log format ["[WMP ZEN] invoked module=Radio Jammer Toggle curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos, player] call Waldo_fnc_ZenJammerToggle;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\interact_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Electronic Warfare", "Jammer - Delete Nearest",
    {
        diag_log format ["[WMP ZEN] invoked module=Radio Jammer Remove curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos, player] call Waldo_fnc_ZenJammerRemove;
    },
    "\a3\ui_f\data\map\markers\military\destroy_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Electronic Warfare", "EMP - Detonate at Cursor",
    {
        diag_log format ["[WMP ZEN] invoked module=EMP Detonation curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call Waldo_fnc_ZenEMP;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\backpack_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Electronic Warfare", "Tracker - Attach to Selected Object",
    {
        diag_log format ["[WMP ZEN] invoked module=Plant Signal Tracker curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call Waldo_fnc_ZenTracker;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\download_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Interface & QA", "Diagnostics - Run Full Pack Audit",
    {
        diag_log format ["[WMP ZEN] invoked module=Full Pack Diagnostics curator=%1 payload=%2", name player, _this];
        [] remoteExecCall ["Waldo_fnc_RunDiagnostics", 2];
        ["DIAGNOSTICS", "Full pack audit requested. Results are written to the server and client RPTs.", "INFO", "DIAGNOSTICS", 6] call Waldo_fnc_FeatureNotifyLocal;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\intel_ca.paa"
] call zen_custom_modules_fnc_register;

missionNamespace setVariable ["Waldo_ZenModuleCount", 47];
missionNamespace setVariable ["Waldo_ZenModulesReady", true];
diag_log format ["[WMP ZEN] Registered %1 categorized WMP modules on clientOwner=%2", missionNamespace getVariable ["Waldo_ZenModuleCount", 47], clientOwner];

// Warm the Vehicle Weapon Loadout pack-wide catalog in the background now, well before a curator is
// likely to actually open "Vehicle Weapon Loadout - Configure" - scanning every CfgVehicles class is
// real work on a large modset, so this trades a background cost paid once at mission start for an
// instant dialog open later instead of blocking the dialog itself on the scan.
[] spawn {[] call Waldo_fnc_VehicleWeaponLoadoutCatalogBuild;};

// Hazard controls are meaningful only when the mission enabled the underlying runtime. Shared
// config can finish after ZEN registration, so add these two entries asynchronously once the
// readiness sentinel is available instead of showing dead controls in every mission.
[] spawn {
    private _deadline = diag_tickTime + 30;
    waitUntil {uiSleep 0.1; missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false] || {diag_tickTime >= _deadline}};
    if !(missionNamespace getVariable ["Waldo_Hazard_Enable", false]) exitWith {
        diag_log format ["[WMP ZEN] Hazard modules not registered on clientOwner=%1: Waldo_Hazard_Enable is false.", clientOwner];
    };
    {
        _x params ["_name", "_feature"];
        private _handler = compile format ["params ['_modulePos', ['_objectPos', objNull]]; ['%1', _modulePos, _objectPos] call Waldo_fnc_FeatureRuntimeZen;", _feature];
        ["WMP Environment", _name, _handler, "\A3\ui_f\data\map\markers\military\warning_CA.paa"] call zen_custom_modules_fnc_register;
    } forEach [["Hazard - Create", "HAZARD_CREATE"], ["Hazard - Remove Nearest", "HAZARD_REMOVE"]];
    missionNamespace setVariable ["Waldo_ZenModuleCount", (missionNamespace getVariable ["Waldo_ZenModuleCount", 47]) + 2];
    diag_log format ["[WMP ZEN] Registered 2 enabled hazard modules on clientOwner=%1.", clientOwner];
};

// Headless-client control modules are registered separately, and only when Waldo_Headless_Enable is
// actually true - unlike every module above, which is always useful regardless of mission config, a
// Zeus menu offering to toggle headless debug output or hand groups to a headless client is pure
// clutter (and a misleading affordance) on the vast majority of missions that never turn HC support
// on. Waldo_Headless_Enable is SHARED-scope config loaded by init.sqf, which is not guaranteed to
// have finished before this file runs (initPlayerLocal.sqf races init.sqf), so this waits on the
// same Waldo_SharedFeatureConfigReady sentinel initPlayerLocal.sqf itself waits on before reading it.
[] spawn {
    private _deadline = diag_tickTime + 30;
    waitUntil {uiSleep 0.1; missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false] || {diag_tickTime >= _deadline}};
    if !(missionNamespace getVariable ["Waldo_Headless_Enable", false]) exitWith {
        diag_log format ["[WMP ZEN] Headless client modules not registered on clientOwner=%1: Waldo_Headless_Enable is false.", clientOwner];
    };

    ["WMP Headless Client", "Toggle Debug Overlay",
        {
            params ["_modulePos", "_objectPos"];
            [_modulePos, _objectPos] call Waldo_fnc_ZenHeadlessDebugToggle;
        },
        "\A3\ui_f\data\igui\cfg\simpletasks\types\intel_ca.paa"
    ] call zen_custom_modules_fnc_register;

    ["WMP Headless Client", "Force Rebalance Now",
        {
            params ["_modulePos", "_objectPos"];
            [_modulePos, _objectPos] call Waldo_fnc_ZenHeadlessForceRebalance;
        },
        "\A3\ui_f\data\igui\cfg\simpletasks\types\rearm_ca.paa"
    ] call zen_custom_modules_fnc_register;

    ["WMP Headless Client", "Manual Group Handoff",
        {
            params ["_modulePos", "_objectPos"];
            [_modulePos, _objectPos] call Waldo_fnc_ZenHeadlessManualHandoff;
        },
        "\A3\ui_f\data\igui\cfg\actions\getincommander_ca.paa"
    ] call zen_custom_modules_fnc_register;

    missionNamespace setVariable ["Waldo_ZenModuleCount", (missionNamespace getVariable ["Waldo_ZenModuleCount", 47]) + 3];
    diag_log format ["[WMP ZEN] Registered 3 headless-client modules on clientOwner=%1 (total now %2).", clientOwner, missionNamespace getVariable ["Waldo_ZenModuleCount", 50]];
    if (missionNamespace getVariable ["Waldo_Headless_Debug", false]) then {
        [true] call Waldo_fnc_HeadlessDebugDisplayLocal;
    };
};

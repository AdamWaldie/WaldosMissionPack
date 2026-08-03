/*
 * Author: WaldoTheWarfighter
 * This function load all custom ZEN modules. Requires Zen Mod to run propperly. The function will terminate if not.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
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

["WMP Combat Systems", "Dynamic AA - Create",
    {
        params ["_modulePos"];
        [_modulePos] call Waldo_fnc_DynamicAAZen;
    },
    "\A3\ui_f\data\map\vehicleicons\iconStaticAA_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Combat Systems", "Dynamic AA - Remove Nearest",
    {
        params ["_modulePos"];
        [_modulePos] call Waldo_fnc_DynamicAARemoveZen;
    },
    "\A3\ui_f\data\map\markers\nato\o_antiair.paa"
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
    ["WMP Mission Flow", "Respawn - Squad Rally Control", "RALLY", "\A3\ui_f\data\map\markers\military\start_CA.paa"],
    ["WMP Interface & QA", "Tactical Display - Register", "TACTICAL_DISPLAY", "\A3\ui_f\data\igui\cfg\simpletasks\types\map_ca.paa"],
    ["WMP Air Operations", "Gunship - Register or Spawn", "GUNSHIP_REGISTER", "\A3\ui_f\data\map\vehicleicons\iconPlane_ca.paa"],
    ["WMP Air Operations", "Gunship - Assign Controller", "GUNSHIP_ASSIGN", "\A3\ui_f\data\igui\cfg\actions\getincommander_ca.paa"],
    ["WMP Air Operations", "Gunship - Set Orbit", "GUNSHIP_ORBIT", "\A3\ui_f\data\igui\cfg\simpletasks\types\map_ca.paa"],
    ["WMP Air Operations", "Gunship - Operational Control", "GUNSHIP_CONTROL", "\A3\ui_f\data\igui\cfg\simpletasks\types\plane_ca.paa"],
    ["WMP Combat Systems", "Hazard - Create", "HAZARD_CREATE", "\A3\ui_f\data\map\markers\military\warning_CA.paa"],
    ["WMP Combat Systems", "Hazard - Remove Nearest", "HAZARD_REMOVE", "\A3\ui_f\data\map\markers\military\warning_CA.paa"],
    ["WMP Mission Tools", "AI Rebalance - Control", "AI", "\A3\ui_f\data\map\vehicleicons\iconMan_ca.paa"]
];

["WMP Air Operations", "Paradrop - Create Drop Zone",
    {params ["_modulePos"]; ["CREATE", _modulePos] call Waldo_fnc_ParadropDropZoneZen;},
    "\A3\ui_f\data\map\vehicleicons\iconPlane_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Combat Systems", "Dynamic AO - Create",
    {
        params ["_modulePos"];
        [_modulePos] call Waldo_fnc_DynamicAOZen;
    },
    "\A3\ui_f\data\map\markers\nato\o_inf.paa"
] call zen_custom_modules_fnc_register;

["WMP Combat Systems", "Dynamic AO - Remove",
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

["WMP Combat Systems", "AI: Create Moving Convoy",
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

["WMP Combat Systems", "Jammer: Place New Emitter",
    {
        diag_log format ["[WMP ZEN] invoked module=Radio Jammer Place curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call Waldo_fnc_ZenJammerPlace;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\interact_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Combat Systems", "Jammer: Toggle Nearest Emitter",
    {
        diag_log format ["[WMP ZEN] invoked module=Radio Jammer Toggle curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos, player] call Waldo_fnc_ZenJammerToggle;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\interact_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Combat Systems", "Jammer: Delete Nearest Emitter",
    {
        diag_log format ["[WMP ZEN] invoked module=Radio Jammer Remove curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos, player] call Waldo_fnc_ZenJammerRemove;
    },
    "\a3\ui_f\data\map\markers\military\destroy_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Combat Systems", "EW: Detonate EMP at Cursor",
    {
        diag_log format ["[WMP ZEN] invoked module=EMP Detonation curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call Waldo_fnc_ZenEMP;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\backpack_ca.paa"
] call zen_custom_modules_fnc_register;

["WMP Combat Systems", "Tracker: Attach to Selected Object",
    {
        diag_log format ["[WMP ZEN] invoked module=Plant Signal Tracker curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call Waldo_fnc_ZenTracker;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\download_ca.paa"
] call zen_custom_modules_fnc_register;

missionNamespace setVariable ["Waldo_ZenModuleCount", 42];
missionNamespace setVariable ["Waldo_ZenModulesReady", true];
diag_log format ["[WMP ZEN] Registered 41 categorized WMP modules on clientOwner=%1", clientOwner];

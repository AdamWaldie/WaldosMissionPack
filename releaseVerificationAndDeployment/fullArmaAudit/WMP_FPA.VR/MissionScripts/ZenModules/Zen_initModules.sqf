/*
 * Author: WaldoTheWarfighter
 * This function load all custom ZEN modules. Requires Zen Mod to run propperly. The function will terminate if not.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
*/

//Check for, and exit if not present: Zeus Enhanced
if !(isClass(configFile >> "CfgPatches" >> "zen_main")) exitWith {};
if (!hasInterface) exitWith {};
if (missionNamespace getVariable ["Waldo_ZenModulesRegistered", false]) exitWith {
    diag_log format ["[WMP ZEN] Core module registration already complete on clientOwner=%1", clientOwner];
};
missionNamespace setVariable ["Waldo_ZenModulesRegistered", true];


//Add ZEN modules
["Waldos Mission Modules", "Supplies: Create Player Crate",
    {
        diag_log format ["[WMP ZEN] invoked module=Player Supply Crate curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call Waldo_fnc_ZenSupplySpawner;
    },
    "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "Mission Flow: End Mission + Show AAR",
    {
        diag_log format ["[WMP ZEN] invoked module=Call Endex curator=%1 payload=%2", name player, _this];
        [] remoteExecCall ["Waldo_fnc_ENDEX", 2];
    },
    "\a3\modules_f\data\portraitmodule_ca.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "Mission Flow: End Mission (No AAR)",
    {
        diag_log format ["[WMP ZEN] invoked module=Custom Mission End curator=%1 payload=%2", name player, _this];
        ["end1"] remoteExec ["BIS_fnc_endMission",0,true];
    },
    "\a3\Missions_F_Orange\Data\Img\Showcase_LawsOfWar\action_end_sim_CA.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "Medical: Create Field Hospital Crate",
    {
        diag_log format ["[WMP ZEN] invoked module=Field Hospital Crate curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos,1] call Waldo_fnc_ZenMedicalSpawner;
    },
    "\z\ACE\addons\medical_gui\ui\cross.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "Fortify: Set Side Budget",

    {
        diag_log format ["[WMP ZEN] invoked module=Fortify Budget Manager curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [] call Waldo_fnc_FortifyBudgetModule;
    },
    "\z\ACE\addons\fortify\ui\hammer_ca.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "AI: Create Moving Convoy",
    {
        diag_log format ["[WMP ZEN] invoked module=Spawn AI Convoy curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos] call Waldo_fnc_ZenConvoyModule;
    },
    "\A3\ui_f\data\map\vehicleicons\iconTruck_ca.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "Respawn: Create Loadout Save Point",
    {
        diag_log format ["[WMP ZEN] invoked module=Loadout Save Point curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos, player] call Waldo_fnc_ZenLoadoutSaveModule;
    },
    "\A3\ui_f\data\map\vehicleicons\iconMan_ca.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "SafeStart: Enable Protection",
    {
        diag_log format ["[WMP ZEN] invoked module=Safestart Activate curator=%1", name player];
        [true] remoteExec ["Waldo_fnc_SafeStart", 2];
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\interact_ca.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "SafeStart: Go Live Now",
    {
        diag_log format ["[WMP ZEN] invoked module=Safestart Go Live curator=%1", name player];
        [false] remoteExec ["Waldo_fnc_SafeStart", 2];
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\attack_ca.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "SafeStart: Start Go-Live Timer",
    {
        diag_log format ["[WMP ZEN] invoked module=Safestart Countdown curator=%1", name player];
        [] call Waldo_fnc_ZenSafeStartTimer;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\download_ca.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "Jammer: Place New Emitter",
    {
        diag_log format ["[WMP ZEN] invoked module=Radio Jammer Place curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call Waldo_fnc_ZenJammerPlace;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\interact_ca.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "Jammer: Toggle Nearest Emitter",
    {
        diag_log format ["[WMP ZEN] invoked module=Radio Jammer Toggle curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos, player] call Waldo_fnc_ZenJammerToggle;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\interact_ca.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "Jammer: Delete Nearest Emitter",
    {
        diag_log format ["[WMP ZEN] invoked module=Radio Jammer Remove curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos, player] call Waldo_fnc_ZenJammerRemove;
    },
    "\a3\ui_f\data\map\markers\military\destroy_ca.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "EW: Detonate EMP at Cursor",
    {
        diag_log format ["[WMP ZEN] invoked module=EMP Detonation curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call Waldo_fnc_ZenEMP;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\backpack_ca.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "Tracker: Attach to Selected Object",
    {
        diag_log format ["[WMP ZEN] invoked module=Plant Signal Tracker curator=%1 payload=%2", name player, _this];
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call Waldo_fnc_ZenTracker;
    },
    "\a3\ui_f\data\igui\cfg\simpletasks\types\download_ca.paa"
] call zen_custom_modules_fnc_register;

missionNamespace setVariable ["Waldo_ZenModuleCount", 15];
diag_log format ["[WMP ZEN] Registered 15 Waldos Mission Modules on clientOwner=%1", clientOwner];

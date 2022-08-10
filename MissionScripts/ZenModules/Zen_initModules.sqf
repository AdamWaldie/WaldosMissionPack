/*
 * Author: Waldo
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


//Add ZEN modules
["Waldos Mission Modules", "Player Supply Crate",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call Waldo_fnc_ZenSupplySpawner;
    },
    "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "Call Endex",
    {
        //[] spawn Waldo_fnc_ENDEX;
        remoteExec ["Waldo_fnc_ENDEX",0,true];
    },
    "\a3\modules_f\data\portraitmodule_ca.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "Custom Mission End",
    {
        ["end1"] remoteExec ["BIS_fnc_endMission",0,true];
    },
    "\a3\Missions_F_Orange\Data\Img\Showcase_LawsOfWar\action_end_sim_CA.paa"
] call zen_custom_modules_fnc_register;

["Waldos Mission Modules", "Field Hospital Crate",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos,1] call Waldo_fnc_ZenMedicalSpawner;
    },
    "\z\ACE\addons\medical_gui\ui\cross.paa"
] call zen_custom_modules_fnc_register;

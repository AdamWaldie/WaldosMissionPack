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
["Waldos Modules", "Player Supply Crate",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call Waldo_fnc_CreateSupplyCrate;
    },
    "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"
] call zen_custom_modules_fnc_register;

["Waldos Modules", "Call Endex",
    {
        [] spawn Waldo_fnc_ENDEX;
    },
    "\a3\modules_f\data\portraitmodule_ca.paa"
] call zen_custom_modules_fnc_register;

["Waldos Modules", "Field Hospital Crate",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos,1] call Waldo_fnc_CreateCCPCrate;
    },
    "\z\ACE\addons\medical_gui\ui\cross.paa"
] call zen_custom_modules_fnc_register;

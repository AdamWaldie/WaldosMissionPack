/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: opens the persistent, multi-tab "Vehicle Customisation - Editor" dialog on the
 * vehicle the module was placed directly on. Replaces the retired "Vehicle Weapon Loadout - Configure",
 * "Vehicle Weapon Loadout - Copy From Nearby Vehicle", "Vehicle Appearance - Set Texture",
 * "Vehicle Appearance - Register Component", and "Vehicle Appearance - Remove/Restore Component"
 * modules with one continuous authoring session: a curator can queue any number of turret, pylon,
 * appearance, and component changes across four tabs into a single Pending Changes list, then either
 * apply them all at once or export one ready-to-paste Eden-init-field snippet. Placement anywhere but
 * directly on a real vehicle is rejected with a notice, same convention as every module here.
 *
 * All dialog construction, tab switching, row collection/validation, and Apply/Export/Clear logic
 * lives in Waldo_fnc_VehCust_promptEditor and its supporting
 * MissionScripts/CombatSystems/VehicleCustomization/ files - this handler only does the placement
 * check and opens the dialog.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module
 * 1: objectPos <OBJECT> - the vehicle the module was dropped on
 *
 * Return Value:
 * Nothing - opens the Vehicle Customisation - Editor dialog.
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenVehicleCustomizationEditor;
 *
 * Current caller: the ZEN "Vehicle Customisation - Editor" module registered by
 * Waldo_fnc_ZenInitModules under category "WMP Vehicle Customisation".
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", ["_objectPos", objNull]];

// Man (soldiers/AI) also inherits from AllVehicles in Arma 3's own CfgVehicles tree, so it must be
// explicitly excluded here too - otherwise placing this directly on a person would pass the gate and
// open a dialog for turret/pylon/appearance/component options that make no sense for a unit.
if (isNull _objectPos || {!(_objectPos isKindOf "AllVehicles")} || {_objectPos isKindOf "Man"}) exitWith {
    ["VEHICLE CUSTOMISATION", "Place this module directly on the vehicle you want to edit.", "WARNING", "VEHCUST_ZEN", 8]
        call Waldo_fnc_FeatureNotifyLocal;
};

diag_log format ["[WMP ZEN] invoked module=Vehicle Customisation - Editor curator=%1 vehicle=%2", name player, typeOf _objectPos];
[_objectPos] call Waldo_fnc_VehCust_promptEditor;

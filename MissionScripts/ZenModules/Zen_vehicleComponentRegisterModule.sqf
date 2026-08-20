/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: registers a reusable physical component for the placed vehicle's exact class,
 * via Waldo_fnc_VehicleComponentCatalogRegister - the "dynamic pickup on the fly" answer to finding
 * and reusing a real selection name. Run Vehicle Appearance - Inspect on this vehicle first to read
 * its real model selection names, then register the one that represents the part here; every future
 * Remove/Restore Component dialog opened on this same vehicle class then offers it as a one-click
 * picker option instead of a typed field. Placement anywhere but directly on a real vehicle is
 * rejected with a notice, same convention as Waldo_fnc_ZenVehicleWeaponLoadout.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module
 * 1: objectPos <OBJECT> - the vehicle whose class the component is registered under
 *
 * Return Value:
 * Nothing - the dialog forwards an authorised registration request to the server.
 *
 * Current caller: the ZEN "Vehicle Appearance - Register Component" module registered by
 * Waldo_fnc_ZenInitModules.
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", "_objectPos"];

if (isNull _objectPos || {!(_objectPos isKindOf "AllVehicles")} || {_objectPos isKindOf "Man"}) exitWith {
    ["VEHICLE APPEARANCE", "Place this module directly on the vehicle whose component you want to register.", "WARNING", "VEHAPP_ZEN", 8]
        call Waldo_fnc_FeatureNotifyLocal;
};

[
    "Vehicle Appearance - Register Component",
    [
        ["EDIT", ["Component Label", "Short curator-facing name, e.g. Remote Weapon Station."], ""],
        ["EDIT", ["Selection Name", "Exact model selection to hide/show - confirm it with Vehicle Appearance - Inspect first."], ""],
        ["EDIT", ["Linked Turret Path (optional)", "e.g. [0] or [-1] - that turret's weapon is also cleared on removal. Leave blank for a purely cosmetic part."], ""]
    ],
    {
        params ["_args", "_pos"];
        _args params ["_label", "_selectionName", "_turretPathText"];
        _pos params ["_vehicle"];
        if (isNull _vehicle) exitWith {
            ["VEHICLE APPEARANCE", "That vehicle no longer exists.", "WARNING", "VEHAPP_ZEN", 8] call Waldo_fnc_FeatureNotifyLocal;
        };
        private _turretPath = parseSimpleArray _turretPathText;
        if !(_turretPath isEqualType []) then { _turretPath = []; };
        diag_log format ["[WMP ZEN] invoked module=Vehicle Appearance - Register Component curator=%1 class=%2 label=%3 selection=%4 turretPath=%5", name player, typeOf _vehicle, _label, _selectionName, _turretPath];
        [[typeOf _vehicle], _label, _selectionName, _turretPath, player] remoteExecCall ["Waldo_fnc_ZenVehicleComponentRegisterServer", 2];
    },
    {},
    [_objectPos]
] call zen_dialog_fnc_create;

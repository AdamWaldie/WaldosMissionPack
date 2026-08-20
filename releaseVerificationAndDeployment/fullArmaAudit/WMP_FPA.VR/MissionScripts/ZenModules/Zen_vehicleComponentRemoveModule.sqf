/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: removes or restores a physical component on the vehicle the module was placed
 * directly on, via Waldo_fnc_VehicleComponentRemove. If a curator previously registered one or more
 * components for this exact vehicle class (Vehicle Appearance - Register Component), the Component
 * picker offers them by name - the "dynamic pickup" beginner path, no typing needed. Otherwise, or to
 * bypass the catalog, "Type manually" falls back to typed selection-name/turret-path fields (confirm
 * the real selection name first with Vehicle Appearance - Inspect). Placement anywhere but directly on
 * a real vehicle is rejected with a notice, same convention as Waldo_fnc_ZenVehicleWeaponLoadout.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module
 * 1: objectPos <OBJECT> - the vehicle the module was dropped on
 *
 * Return Value:
 * Nothing - the dialog forwards an authorised remove/restore request to the server.
 *
 * Current caller: the ZEN "Vehicle Appearance - Remove/Restore Component" module registered by
 * Waldo_fnc_ZenInitModules.
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", "_objectPos"];

if (isNull _objectPos || {!(_objectPos isKindOf "AllVehicles")} || {_objectPos isKindOf "Man"}) exitWith {
    ["VEHICLE APPEARANCE", "Place this module directly on the vehicle whose component you want to remove or restore.", "WARNING", "VEHAPP_ZEN", 8]
        call Waldo_fnc_FeatureNotifyLocal;
};

private _catalog = missionNamespace getVariable ["Waldo_VehicleComponentCatalog", createHashMap];
private _entries = _catalog getOrDefault [typeOf _objectPos, []];
private _componentValues = ["MANUAL"];
private _componentLabels = [if (count _entries > 0) then {"Type manually (ignore registered components below)"} else {"Type manually (no components registered for this vehicle class yet)"}];
for "_i" from 0 to ((count _entries) - 1) do {
    private _entry = _entries select _i;
    _componentValues pushBack (str _i);
    _componentLabels pushBack format ["%1 (selection: %2)", _entry select 0, _entry select 1];
};

[
    "Vehicle Appearance - Remove/Restore Component",
    [
        ["LIST", ["Component", "A registered component for this vehicle class, or type manually below."], [_componentValues, _componentLabels, 0, 6]],
        ["EDIT", ["Selection Name (manual)", "Used only when Component above is 'Type manually'. Confirm the real name with Vehicle Appearance - Inspect first."], ""],
        ["EDIT", ["Linked Turret Path (manual, optional)", "e.g. [0] or [-1] - that turret's weapon is also cleared on removal. Leave blank for a purely cosmetic part."], ""],
        ["TOOLBOX:WIDE", ["Action", "Remove hides the part (and clears its linked weapon, if any). Restore only re-shows the part - it does not re-arm the weapon."], [0, 1, 2, ["Remove", "Restore"]]]
    ],
    {
        params ["_args", "_pos"];
        _args params ["_componentKey", "_manualSelection", "_manualTurretText", "_actionIndex"];
        _pos params ["_vehicle"];
        if (isNull _vehicle) exitWith {
            ["VEHICLE APPEARANCE", "That vehicle no longer exists.", "WARNING", "VEHAPP_ZEN", 8] call Waldo_fnc_FeatureNotifyLocal;
        };
        private _selectionName = _manualSelection;
        private _turretPath = parseSimpleArray _manualTurretText;
        if !(_turretPath isEqualType []) then { _turretPath = []; };
        if (_componentKey != "MANUAL") then {
            private _catalog = missionNamespace getVariable ["Waldo_VehicleComponentCatalog", createHashMap];
            private _entries = _catalog getOrDefault [typeOf _vehicle, []];
            private _index = parseNumber _componentKey;
            if (_index >= 0 && {_index < count _entries}) then {
                private _entry = _entries select _index;
                _selectionName = _entry select 1;
                _turretPath = _entry select 2;
            };
        };
        if (_selectionName == "") exitWith {
            ["VEHICLE APPEARANCE", "No component selected and no selection name typed - nothing to do.", "WARNING", "VEHAPP_ZEN", 8] call Waldo_fnc_FeatureNotifyLocal;
        };
        private _hide = _actionIndex == 0;
        diag_log format ["[WMP ZEN] invoked module=Vehicle Appearance - Remove/Restore Component curator=%1 vehicle=%2 selection=%3 turretPath=%4 hide=%5", name player, typeOf _vehicle, _selectionName, _turretPath, _hide];
        [_vehicle, _selectionName, _turretPath, _hide, player] remoteExecCall ["Waldo_fnc_ZenVehicleComponentRemoveServer", 2];
    },
    {},
    [_objectPos]
] call zen_dialog_fnc_create;

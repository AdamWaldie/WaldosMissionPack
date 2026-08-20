/*
 * Author: WaldoTheWarfighter
 * Registers a reusable, named physical component for a vehicle CLASS (not one instance) - "on this
 * class of vehicle, the model selection called X is its turret cupola, and removing it should also
 * clear turret path Y". There is no engine flag marking a model selection as a removable physical
 * component the way allTurrets/weaponsTurret enumerate real weapons, so this has to be authored once
 * by a mission maker or curator (typically after using Vehicle Appearance - Inspect to find the real
 * selection name), not auto-detected - this function is the reusable memory for that discovery, so it
 * only has to happen once per vehicle class, not once per placed vehicle. Empty by default; WMP ships
 * no pre-seeded entries, since a wrong selection name presented as fact is worse than none at all.
 *
 * Server-authoritative broadcast registry (Waldo_VehicleComponentCatalog, a HashMap keyed by vehicle
 * class, each value an array of [componentLabel, selectionName, turretPath]) - callable from an
 * object's own Eden init field, initServer.sqf, or a script with no isServer wrapper, same convention
 * as Waldo_fnc_Jammer. Re-registering the same label for the same class replaces that entry instead of
 * duplicating it.
 *
 * Arguments:
 * 0: VehicleClass <STRING or ARRAY of STRING> - one class, or several classes sharing the same part
 *    (e.g. variants of the same base vehicle).
 * 1: ComponentLabel <STRING> - a short curator-facing name, e.g. "Remote Weapon Station".
 * 2: SelectionName <STRING> - the exact model selection to hide/show (find it with
 *    Waldo_fnc_VehicleAppearanceInspect or the Eden Debug Console's selectionNames command).
 * 3: TurretPath <ARRAY> (optional, default []) - a turret path (e.g. [-1] or [0]) whose weapon should
 *    also be cleared when this component is removed. Leave [] (default) for a purely cosmetic part
 *    with no associated weapon.
 *
 * Return Value:
 * Boolean - true once registered (or forwarded to the server); false on invalid arguments.
 *
 * Example:
 * // After confirming the real selection name on the actual vehicle with Vehicle Appearance - Inspect:
 * [["B_MRAP_01_F", "B_MRAP_01_gmg_F"], "Remote Weapon Station", "rws_base", [0]]
 *     call Waldo_fnc_VehicleComponentCatalogRegister;
 *
 * Current callers: mission scripts/initServer.sqf, and the ZEN "Vehicle Appearance - Register
 * Component" module (via Waldo_fnc_ZenVehicleComponentRegisterServer).
 */

params [
    ["_classes", "", ["", []]],
    ["_label", "", [""]],
    ["_selectionName", "", [""]],
    ["_turretPath", [], [[]]]
];
if (_classes isEqualType "") then {_classes = [_classes];};
_classes = _classes select {_x isEqualType "" && {_x != ""}};
if (count _classes == 0 || {_label == ""} || {_selectionName == ""}) exitWith {
    diag_log "[WMP VEHAPP CATALOG] Waldo_fnc_VehicleComponentCatalogRegister called with invalid arguments - ignored.";
    false
};

if !(isServer) exitWith {
    [_classes, _label, _selectionName, _turretPath] remoteExec ["Waldo_fnc_VehicleComponentCatalogRegister", 2];
    true
};

private _catalog = missionNamespace getVariable ["Waldo_VehicleComponentCatalog", createHashMap];
{
    private _class = _x;
    private _entries = _catalog getOrDefault [_class, []];
    _entries = _entries select {(_x select 0) != _label};
    _entries pushBack [_label, _selectionName, _turretPath];
    _catalog set [_class, _entries];
} forEach _classes;
missionNamespace setVariable ["Waldo_VehicleComponentCatalog", _catalog, true];
diag_log format ["[WMP VEHAPP CATALOG] registered label=%1 selection=%2 turretPath=%3 classes=%4", _label, _selectionName, _turretPath, _classes];
true

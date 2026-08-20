/*
 * Author: WaldoTheWarfighter
 * Removes or restores a named physical component on a vehicle - hides/shows the given model selection
 * via Waldo_fnc_VehicleAppearanceApply, and when removing (hide=true) with a turretPath also clears
 * that turret's weapon via Waldo_fnc_VehicleWeaponLoadoutApply, so "remove this vehicle's turret"
 * genuinely means both gone-looking and gone-functioning in one call, instead of a mission maker
 * having to remember to chain both features themselves. Restoring (hide=false) only re-shows the
 * model selection - it does NOT restore whatever weapon/magazine the turret held before, since that
 * was never recorded; re-arm it separately with Waldo_fnc_VehicleWeaponLoadoutApply if needed.
 *
 * Server-authoritative - callable from an object's own Eden init field with no isServer wrapper, same
 * convention as Waldo_fnc_Jammer/Waldo_fnc_VehicleWeaponLoadoutApply.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: SelectionName <STRING> - the model selection to hide/show (validated against selectionNames
 *    vehicle by Waldo_fnc_VehicleAppearanceApply).
 * 2: TurretPath <ARRAY> (optional, default []) - a turret path whose weapon is also cleared when
 *    hiding. Leave [] for a purely cosmetic component with no associated weapon.
 * 3: Hide <BOOL> (optional, default true) - true removes (hide + clear weapon), false restores
 *    (show only).
 *
 * Return Value:
 * Array [appearanceResult, weaponResult] - appearanceResult is Waldo_fnc_VehicleAppearanceApply's
 * single-row result [ok, detail]; weaponResult is Waldo_fnc_VehicleWeaponLoadoutApply's single-row
 * result, or [] when no turretPath was given.
 *
 * Example:
 * // Visually and functionally remove a vehicle's RWS, once its selection/turret path is known:
 * [this, "rws_base", [0], true] call Waldo_fnc_VehicleComponentRemove;
 * // Beginner-friendly form, using a catalog entry registered once for this vehicle's class:
 * private _entry = (missionNamespace getVariable ["Waldo_VehicleComponentCatalog", createHashMap])
 *     getOrDefault [typeOf this, []] select 0;
 * [this, _entry select 1, _entry select 2, true] call Waldo_fnc_VehicleComponentRemove;
 *
 * Current callers: mission scripts, and the ZEN "Vehicle Appearance - Remove/Restore Component"
 * module (via Waldo_fnc_ZenVehicleComponentRemoveServer).
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_selectionName", "", [""]],
    ["_turretPath", [], [[]]],
    ["_hide", true, [true]]
];

if (isNull _vehicle || {!(_vehicle isKindOf "AllVehicles")} || {_vehicle isKindOf "Man"} || {_selectionName == ""}) exitWith {
    diag_log "[WMP VEHAPP COMPONENT] Waldo_fnc_VehicleComponentRemove called with an invalid vehicle or selection - ignored.";
    [[false, "invalid vehicle or selection"], []]
};

if !(isServer) exitWith {
    [_vehicle, _selectionName, _turretPath, _hide] remoteExec ["Waldo_fnc_VehicleComponentRemove", 2];
    [[], []]
};

private _appearanceAction = if (_hide) then {"HIDE"} else {"SHOW"};
private _appearanceResults = [_vehicle, [["SELECTION", _selectionName, _appearanceAction, ""]]] call Waldo_fnc_VehicleAppearanceApply;
private _appearanceResult = _appearanceResults param [0, [false, "no result"]];

private _weaponResult = [];
if (_hide && {count _turretPath > 0}) then {
    private _weaponResults = [_vehicle, [["TURRET", _turretPath, -1, "CLEAR", "", "", 0]]] call Waldo_fnc_VehicleWeaponLoadoutApply;
    _weaponResult = _weaponResults param [0, [false, "no result"]];
};

diag_log format ["[WMP VEHAPP COMPONENT] vehicle=%1 selection=%2 turretPath=%3 hide=%4 appearance=%5 weapon=%6", typeOf _vehicle, _selectionName, _turretPath, _hide, _appearanceResult, _weaponResult];
[_appearanceResult, _weaponResult]

/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: copies another nearby vehicle's real turret/pylon loadout onto the vehicle the
 * module was placed directly on, via Waldo_fnc_VehicleWeaponLoadoutCopy - the strongest
 * beginner-friendly answer to "how do I know the exact classnames": with this, a curator never types
 * one. Placement anywhere but directly on a real vehicle is rejected, same convention as
 * Waldo_fnc_ZenVehicleWeaponLoadout. The source-vehicle list is discovered live (nearestObjects
 * around the target, same pattern as Waldo_fnc_ZenConvoyModule), nearest first, so only vehicles
 * actually present nearby are ever offered - never hand-typed.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module
 * 1: objectPos <OBJECT> - the target vehicle the module was dropped on
 *
 * Return Value:
 * Nothing - the dialog forwards an authorised copy request to the server.
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenVehicleWeaponLoadoutCopy;
 *
 * Current caller: the ZEN "Vehicle Weapon Loadout - Copy From Nearby Vehicle" module registered by
 * Waldo_fnc_ZenInitModules.
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", "_objectPos"];

if (isNull _objectPos || {!(_objectPos isKindOf "AllVehicles")} || {_objectPos isKindOf "Man"}) exitWith {
    ["VEHICLE WEAPON LOADOUT", "Place this module directly on the vehicle you want to receive a copied loadout.", "WARNING", "VEHWPN_ZEN", 8]
        call Waldo_fnc_FeatureNotifyLocal;
};

// GROUP-object LIST values are already precedented and working elsewhere in this codebase
// (Zen_headlessManualHandoffModule.sqf's Group control) - OBJECT is the same kind of reference/handle
// type, so vehicle objects are used directly here rather than string-encoding them.
private _nearby = (nearestObjects [_objectPos, ["AllVehicles"], 100]) select {
    _x != _objectPos && {!(_x isKindOf "Man")}
};
_nearby = _nearby apply {[_x, _objectPos distance _x]};
_nearby = [_nearby, [], {_x select 1}, "ASCEND"] call BIS_fnc_sortBy;
_nearby = _nearby select [0, 10 min (count _nearby)];

if (_nearby isEqualTo []) exitWith {
    ["VEHICLE WEAPON LOADOUT", "No other vehicle was found within 100m to copy a loadout from.", "WARNING", "VEHWPN_ZEN", 8]
        call Waldo_fnc_FeatureNotifyLocal;
};

private _sourceValues = _nearby apply {_x select 0};
private _sourceLabels = _nearby apply {
    _x params ["_veh", "_dist"];
    format ["%1 (%2) - %3m", getText (configFile >> "CfgVehicles" >> (typeOf _veh) >> "displayName"), typeOf _veh, round _dist]
};

[
    "Vehicle Weapon Loadout - Copy",
    [
        ["LIST", ["Copy loadout from", "The nearby vehicle to copy the turret/pylon loadout from, nearest first."], [_sourceValues, _sourceLabels, 0, 6]],
        ["CHECKBOX", ["Copy Turret Weapons", "Copy every turret path that exists on both vehicles."], true, false],
        ["CHECKBOX", ["Copy Pylon Ordnance", "Copy every pylon, up to however many both vehicles have, including exact remaining ammo."], true, false]
    ],
    {
        params ["_args", "_pos"];
        _args params ["_source", "_copyTurrets", "_copyPylons"];
        _pos params ["_target"];
        if (isNull _target) exitWith {
            ["VEHICLE WEAPON LOADOUT", "That vehicle no longer exists.", "WARNING", "VEHWPN_ZEN", 8] call Waldo_fnc_FeatureNotifyLocal;
        };
        if (isNull _source) exitWith {
            ["VEHICLE WEAPON LOADOUT", "The selected source vehicle no longer exists.", "WARNING", "VEHWPN_ZEN", 8] call Waldo_fnc_FeatureNotifyLocal;
        };
        diag_log format ["[WMP ZEN] invoked module=Vehicle Weapon Loadout Copy curator=%1 source=%2 target=%3", name player, typeOf _source, typeOf _target];
        [_source, _target, [["copyTurrets", _copyTurrets], ["copyPylons", _copyPylons]], player] remoteExecCall ["Waldo_fnc_ZenVehicleWeaponLoadoutCopyServer", 2];
    },
    {},
    [_objectPos]
] call zen_dialog_fnc_create;

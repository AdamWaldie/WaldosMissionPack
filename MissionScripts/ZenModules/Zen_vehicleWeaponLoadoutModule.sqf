/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: edits the weapon/ammo loadout of the vehicle the module was placed directly
 * on - a turret weapon (add/replace/remove/clear) or an aircraft pylon (set/clear ordnance) - via
 * Waldo_fnc_VehicleWeaponLoadoutApply. Placement anywhere but directly on a real vehicle is rejected
 * with a notice, same convention as Waldo_fnc_ZenTracker. Both the turret and pylon option lists are
 * discovered live from the actual placed vehicle (allTurrets / getPylonMagazines /
 * TransportPylonsComponent), never hand-typed, so only choices that vehicle genuinely supports are
 * ever offered - matching the fresh-per-open list pattern Waldo_fnc_ZenJammerPlace and
 * Waldo_fnc_ZenHeadlessManualHandoff already use.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module
 * 1: objectPos <OBJECT> - the vehicle the module was dropped on
 *
 * Return Value:
 * Nothing - the dialog forwards an authorised loadout-change request to the server.
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenVehicleWeaponLoadout;
 *
 * Current caller: the ZEN "Vehicle Weapon Loadout - Configure" module registered by
 * Waldo_fnc_ZenInitModules.
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", "_objectPos"];

if (isNull _objectPos || {!(_objectPos isKindOf "AllVehicles")}) exitWith {
    ["VEHICLE WEAPON LOADOUT", "Place this module directly on the vehicle you want to edit.", "WARNING", "VEHWPN_ZEN", 8]
        call Waldo_fnc_FeatureNotifyLocal;
};

private _turretPaths = [[-1]] + (allTurrets [_objectPos, true]);
private _turretLabels = _turretPaths apply {
    private _current = _objectPos weaponsTurret _x;
    private _currentText = if (count _current > 0) then {
        (_current apply {getText (configFile >> "CfgWeapons" >> _x >> "displayName")}) joinString ", "
    } else {"empty"};
    format ["Turret %1 - %2", _x, _currentText]
};

private _pylonCount = count (getPylonMagazines _objectPos);
private _pylonValues = [-1];
private _pylonLabels = ["No pylons on this vehicle"];
if (_pylonCount > 0) then {
    private _pylonClasses = (configProperties [
        configFile >> "CfgVehicles" >> (typeOf _objectPos) >> "Components" >> "TransportPylonsComponent" >> "Pylons",
        "isClass _x"
    ]) apply {configName _x};
    private _currentPylonMags = getPylonMagazines _objectPos;
    _pylonValues = [];
    _pylonLabels = [];
    for "_i" from 0 to (_pylonCount - 1) do {
        private _pylonName = if (_i < count _pylonClasses) then {
            getText (configFile >> "CfgVehicles" >> (typeOf _objectPos) >> "Components" >> "TransportPylonsComponent" >> "Pylons" >> (_pylonClasses select _i) >> "displayName")
        } else {""};
        if (_pylonName == "") then {_pylonName = format ["Pylon %1", _i + 1]};
        private _current = _currentPylonMags param [_i, ""];
        _pylonValues pushBack (_i + 1);
        _pylonLabels pushBack format ["%1 - %2", _pylonName, if (_current == "") then {"empty"} else {_current}];
    };
};

private _targetOptions = [["Turret weapon", "Add, replace, remove, or clear a turret's weapon/ammo."]];
if (_pylonCount > 0) then {
    _targetOptions pushBack ["Aircraft pylon", "Set or clear a hardpoint's ordnance."];
};

[
    "Vehicle Weapon Loadout",
    [
        ["TOOLBOX:WIDE", ["Loadout Target", "Whether this change applies to a turret weapon or an aircraft pylon."], [0, 1, count _targetOptions, _targetOptions]],
        ["LIST", ["Turret", "Which turret to change (used when target is Turret weapon)."], [_turretPaths, _turretLabels, 0, 6]],
        ["TOOLBOX:WIDE", ["Turret Action", "What to do to the selected turret."], [0, 1, 4, ["Add Weapon", "Replace Turret", "Remove Weapon", "Clear Turret"]]],
        ["EDIT", ["Weapon Classname", "Exact CfgWeapons class to add/replace/remove, e.g. arifle_MX_F. Ignored for Clear and for pylons."], ""],
        ["EDIT", ["Magazine Classname", "Exact CfgMagazines class. For a pylon this is the ordnance/magazine itself."], ""],
        ["SLIDER", ["Magazine Count", "Rounds loaded into a turret magazine. Ignored for pylons and for Remove/Clear."], [1, 200, 1, 0], false],
        ["LIST", ["Pylon", "Which hardpoint to change (used when target is Aircraft pylon)."], [_pylonValues, _pylonLabels, 0, 6]],
        ["TOOLBOX:WIDE", ["Pylon Action", "Set the pylon's ordnance, or clear it empty."], [0, 1, 2, ["Set Ordnance", "Clear Pylon"]]]
    ],
    {
        params ["_args", "_pos"];
        _args params ["_targetIndex", "_turretPath", "_turretActionIndex", "_weaponClass", "_magazineClass", "_magazineCount", "_pylonIndex", "_pylonActionIndex"];
        _pos params ["_vehicle"];
        if (isNull _vehicle) exitWith {
            ["VEHICLE WEAPON LOADOUT", "That vehicle no longer exists.", "WARNING", "VEHWPN_ZEN", 8] call Waldo_fnc_FeatureNotifyLocal;
        };
        private _row = [];
        if (_targetIndex == 0) then {
            private _action = ["ADD", "REPLACE", "REMOVE", "CLEAR"] param [_turretActionIndex, "ADD"];
            _row = ["TURRET", _turretPath, -1, _action, _weaponClass, _magazineClass, round _magazineCount];
        } else {
            private _action = ["SET", "CLEAR"] param [_pylonActionIndex, "SET"];
            _row = ["PYLON", [-1], _pylonIndex, _action, "", _magazineClass, 0];
        };
        diag_log format ["[WMP ZEN] invoked module=Vehicle Weapon Loadout curator=%1 vehicle=%2 row=%3", name player, typeOf _vehicle, _row];
        [_vehicle, [_row], player] remoteExecCall ["Waldo_fnc_ZenVehicleWeaponLoadoutServer", 2];
    },
    {},
    [_objectPos]
] call zen_dialog_fnc_create;

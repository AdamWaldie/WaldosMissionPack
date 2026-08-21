/*
 * Author: WaldoTheWarfighter
 * Enumerates the magazines a weapon is configured to accept across every muzzle. It combines Arma's
 * compatibleMagazines result with the weapon's inherited top-level magazines[] and each named muzzle's
 * magazines[] array. The config fallback matters for missile launchers because the engine command is
 * documented to return no result for missiles; it also prevents a vehicle turret's unrelated magazine
 * list being assigned to every weapon mounted on that turret.
 *
 * No live vehicle is needed, so this also works for a weapon selected from the pack-wide catalogue or
 * typed manually before it is mounted. Unknown/non-magazine entries are discarded and results are
 * de-duplicated before being shown to the curator.
 *
 * Arguments:
 * 0: Weapon Classname <STRING> - a real CfgWeapons class. An empty string or unknown class returns [].
 *
 * Return Value:
 * Array of [magazineClass <STRING>, displayName <STRING>], sorted by displayName - same 2-element
 * row shape Waldo_fnc_VehicleWeaponLoadoutCatalogBuild's own pylonCatalog rows already use, so
 * callers can populate a combo from either the same way.
 *
 * Example:
 * private _magazines = ["arifle_MX_F"] call Waldo_fnc_VehicleWeaponLoadoutMagazinesForWeapon;
 *
 * Current callers: vehicleWeaponLoadoutCatalogBuild.sqf (per-weapon catalog defaults),
 * vehicleCustomizationPromptEditor.sqf (live Magazine combo), and
 * vehicleCustomizationCollectTurretRow.sqf (final compatibility validation before queueing).
 */

params [["_weaponClass", "", [""]]];
if (_weaponClass == "" || {!(isClass (configFile >> "CfgWeapons" >> _weaponClass))}) exitWith {[]};

private _weaponConfig = configFile >> "CfgWeapons" >> _weaponClass;
private _rawMagazines = compatibleMagazines _weaponClass;
_rawMagazines append (getArray (_weaponConfig >> "magazines"));
{
    if (_x != "this") then {
        _rawMagazines append (getArray (_weaponConfig >> _x >> "magazines"));
    };
} forEach (getArray (_weaponConfig >> "muzzles"));
private _seen = [];
private _rows = [];
{
    private _magClass = _x;
    if !(_magClass in _seen) then {
        _seen pushBack _magClass;
        if (isClass (configFile >> "CfgMagazines" >> _magClass)) then {
            private _displayName = getText (configFile >> "CfgMagazines" >> _magClass >> "displayName");
            if (_displayName == "") then {_displayName = _magClass;};
            _rows pushBack [_magClass, _displayName];
        };
    };
} forEach _rawMagazines;

[_rows, [], {_x select 1}, "ASCEND"] call BIS_fnc_sortBy

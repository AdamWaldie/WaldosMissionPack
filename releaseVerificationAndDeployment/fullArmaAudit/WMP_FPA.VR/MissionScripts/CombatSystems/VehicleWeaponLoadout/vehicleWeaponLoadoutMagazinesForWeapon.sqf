/*
 * Author: WaldoTheWarfighter
 * Enumerates the magazines a given weapon class is actually configured to accept, straight from that
 * weapon's own CfgWeapons >> "magazines" config array - the canonical, always-available source (no
 * live vehicle instance needed, so this works even for a weapon a curator just typed by hand and
 * hasn't mounted anywhere yet). Built for the ZEN "Vehicle Customisation - Editor" dialog's Magazine
 * combo, which repopulates from this every time the Weapon combo's selection changes, so magazine
 * choices are always filtered to what the currently-selected weapon can actually load.
 *
 * Deliberately not the same thing as Waldo_fnc_VehicleWeaponLoadoutApply's own compatibleMagazines
 * warning check: that command needs a live muzzle context and is only ever used there as an
 * informational log, never a filter. This function instead reads the weapon class's own declared
 * magazine list directly, which is exactly what a dropdown of "what can I put in this weapon" needs.
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
 * Current callers: MissionScripts/CombatSystems/VehicleCustomization/vehicleCustomizationPromptEditor.sqf
 * (the Turret tab's Weapon combo's LBSelChanged handler, to repopulate the Magazine combo).
 */

params [["_weaponClass", "", [""]]];
if (_weaponClass == "" || {!(isClass (configFile >> "CfgWeapons" >> _weaponClass))}) exitWith {[]};

private _rawMagazines = getArray (configFile >> "CfgWeapons" >> _weaponClass >> "magazines");
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

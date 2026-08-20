/*
 * Author: WaldoTheWarfighter
 * Read-only helper: reports a vehicle's exact turret and pylon weapon/magazine classnames, plus a
 * ready-to-paste Waldo_fnc_VehicleWeaponLoadoutApply row for each - the beginner-friendly answer to
 * "how do I find the exact classname for a weapon/magazine I want to use elsewhere". Point it at any
 * vehicle - including a stock/vanilla one whose loadout you like - and copy the printed rows onto a
 * different vehicle. Never mutates anything; safe to call on any machine, no server hop, no
 * authorisation needed (nothing here is more sensitive than looking at the vehicle in Eden already
 * would tell you).
 *
 * Arguments:
 * 0: Vehicle <OBJECT> - the vehicle to inspect.
 *
 * Return Value:
 * Array [turretReport, pylonReport, reportText]:
 *   turretReport: Array of [turretPath, weapons[], magazines[]] - magazines[] is deduplicated and is
 *     everything magazinesTurret reports for that path, not necessarily paired to one specific weapon
 *     (a turret with more than one weapon has no per-weapon magazine association exposed by the
 *     engine).
 *   pylonReport: Array of [pylonIndex, pylonName, currentMagazine] - currentMagazine is "" when empty.
 *   reportText: STRING - the same data as one multi-line, hint-ready report, each turret/pylon
 *     followed by a copy-paste-ready row literal. A turret weapon identified as the vehicle's horn
 *     (by CfgWeapons displayName - the engine has no other reliable "this is not a combat weapon"
 *     flag) is reported but never gets a paste-ready row, since it is never the weapon a mission maker
 *     means by "this vehicle's weapon".
 *
 * Example:
 * [cursorObject] call Waldo_fnc_VehicleWeaponLoadoutInspect;
 * hint ((cursorObject call Waldo_fnc_VehicleWeaponLoadoutInspect) select 2);
 *
 * Current caller: the ZEN "Vehicle Weapon Loadout - Inspect" module.
 */

params [["_vehicle", objNull, [objNull]]];

// Same AllVehicles-minus-Man gate as Waldo_fnc_VehicleWeaponLoadoutApply - Man also inherits from
// AllVehicles in Arma 3's own CfgVehicles tree, so it must be excluded explicitly.
if (isNull _vehicle || {!(_vehicle isKindOf "AllVehicles")} || {_vehicle isKindOf "Man"}) exitWith {
    [[], [], "Not a valid vehicle to inspect."]
};

private _displayName = getText (configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "displayName");
private _lines = [format ["--- %1 (%2) ---", _displayName, typeOf _vehicle]];

// The engine's own CfgWeapons tree carries a vehicle's horn as an ordinary weapon entry (it has to,
// to be selectable/switchable like one), but it is never a combat weapon a mission maker means when
// they ask for "this vehicle's weapon" - flagged here by display name so Inspect's ready-to-paste
// rows never suggest REPLACE-ing a real weapon with a horn, or a horn with a real weapon by mistake.
private _isHornWeapon = {
    toLower (getText (configFile >> "CfgWeapons" >> _this >> "displayName")) == "horn"
};

private _turretPaths = [[-1]] + (allTurrets [_vehicle, true]);
private _turretReport = [];
{
    private _path = _x;
    private _weapons = _vehicle weaponsTurret _path;
    private _magazines = (_vehicle magazinesTurret _path) arrayIntersect (_vehicle magazinesTurret _path);
    _turretReport pushBack [_path, _weapons, _magazines];
    if (count _weapons == 0) then {
        _lines pushBack format ["Turret %1: empty", _path];
    } else {
        {
            private _weaponClass = _x;
            if (_weaponClass call _isHornWeapon) then {
                _lines pushBack format ["Turret %1: weapon=%2 (horn - not a combat weapon, no paste row generated)", _path, _weaponClass];
            } else {
                // Best-effort suggested magazine: whichever currently-loaded magazine is documented
                // compatible with this weapon's primary muzzle, falling back to the first loaded
                // magazine, falling back to none - a turret with more than one weapon has no per-weapon
                // magazine association exposed by the engine, so this is a starting point to edit, not a
                // guaranteed-exact pairing.
                private _compatible = compatibleMagazines _weaponClass;
                private _suggestedMag = _magazines select {_x in _compatible};
                private _magForRow = if (count _suggestedMag > 0) then {_suggestedMag select 0} else {_magazines param [0, ""]};
                _lines pushBack format [
                    "Turret %1: weapon=%2 magazines=%3",
                    _path, _weaponClass, _magazines
                ];
                // magazineCount is left at 1 as a starting point regardless of whether a magazine was
                // found - Waldo_fnc_VehicleWeaponLoadoutApply ignores it entirely when magazineClass is
                // "", so this never produces a misleading row.
                _lines pushBack format [
                    '["TURRET", %1, -1, "REPLACE", "%2", "%3", 1],',
                    _path, _weaponClass, _magForRow
                ];
            };
        } forEach _weapons;
    };
} forEach _turretPaths;

private _pylonMags = getPylonMagazines _vehicle;
private _pylonCount = count _pylonMags;
private _pylonReport = [];
if (_pylonCount > 0) then {
    _lines pushBack "";
    private _pylonClasses = (configProperties [
        configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "Components" >> "TransportPylonsComponent" >> "Pylons",
        "isClass _x"
    ]) apply {configName _x};
    for "_i" from 0 to (_pylonCount - 1) do {
        private _pylonName = if (_i < count _pylonClasses) then {
            getText (configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "Components" >> "TransportPylonsComponent" >> "Pylons" >> (_pylonClasses select _i) >> "displayName")
        } else {""};
        if (_pylonName == "") then {_pylonName = format ["Pylon %1", _i + 1]};
        private _current = _pylonMags param [_i, ""];
        _pylonReport pushBack [_i + 1, _pylonName, _current];
        _lines pushBack format ["Pylon %1 (%2): %3", _i + 1, _pylonName, if (_current == "") then {"empty"} else {_current}];
        if (_current != "") then {
            _lines pushBack format ['["PYLON", [-1], %1, "SET", "", "%2", 0],', _i + 1, _current];
        };
    };
};

[_turretReport, _pylonReport, (_lines joinString "\n")]

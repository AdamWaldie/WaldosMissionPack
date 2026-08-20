/*
 * Author: WaldoTheWarfighter
 * Builds and caches a pack-wide catalog of turret weapons (with a representative magazine set) and
 * pylon-usable ordnance, discovered live from the currently loaded modset's config - not a
 * hand-curated list, so a mod's own vehicles/ordnance show up automatically. This is the pack-wide
 * counterpart to the Vehicle Weapon Loadout - Configure module's existing "on this vehicle only" pick
 * lists: scanning every CfgVehicles class recursively is real, non-trivial work on a large modset, so
 * the result is cached for the rest of the mission (config data is immutable during a mission, the
 * same justification Waldo_fnc_ResolveVehicleClassPool already documents for its own cache) rather
 * than rebuilt on every dialog open.
 *
 * Discovery technique:
 *  - Turret weapons: for every CfgVehicles class, a manual, explicit walk of only its own "Turrets"
 *    class chain (recursing into nested Turrets for sub-turrets/optics, the same structure allTurrets
 *    itself walks at runtime) reads each turret entry's weapons[]/magazines[] arrays directly. This is
 *    deliberately NOT the blanket configProperties [.., true] full-tree recursion
 *    Waldo_fnc_GunshipRegister uses to test for "does an armed turret exist anywhere" on one candidate
 *    class - applied per-class across the entire CfgVehicles tree that same blanket recursion walks
 *    into every unrelated subtree too (Sounds, HitPoints, Reflectors, animations, ...), which is both
 *    needlessly expensive at this scale and floods the RPT with spurious engine "'weapons/' is not a
 *    class" warnings wherever an unrelated property happens to share that name - confirmed against a
 *    submitted RPT during this feature's own testing. Each turret entry's sibling magazines[] array
 *    (the same turret's declared magazine list) is stored as that weapon's representative default - a
 *    starting point to edit, not a compatibility guarantee, the same honesty standard
 *    Waldo_fnc_VehicleWeaponLoadoutApply already documents for compatibleMagazines.
 *  - Pylon ordnance: every CfgMagazines entry carrying a non-empty pylonWeapon property (the
 *    documented, standard marker for pylon-usable ordnance) is catalogued directly - a single
 *    top-level CfgMagazines pass, no per-vehicle recursion needed.
 *
 * Locality: interface-client-local only. This reads config data, identical on every machine, so
 * there is nothing to broadcast or synchronise - each client that needs the catalog builds and caches
 * its own copy once.
 *
 * Arguments:
 * None.
 *
 * Return Value:
 * Array [turretCatalog, pylonCatalog]:
 *   turretCatalog: [[weaponClass, displayName, magazineClasses[]], ...], sorted by displayName.
 *   pylonCatalog: [[magazineClass, displayName], ...], sorted by displayName.
 * Both are cached in missionNamespace and returned as-is on every call after the first.
 *
 * Current callers: Waldo_fnc_ZenInitModules (kicks off a background build early, via spawn, so the
 * cache is normally already warm by the time a curator opens the Vehicle Customisation - Editor);
 * vehicleCustomizationPromptEditor.sqf reads the cache directly and does not call this synchronously.
 *
 * Example:
 * [] spawn Waldo_fnc_VehicleWeaponLoadoutCatalogBuild; // warm the cache in the background
 * private _catalogs = [] call Waldo_fnc_VehicleWeaponLoadoutCatalogBuild; // blocks until built
 */

if !(hasInterface) exitWith {[[], []]};

if !(isNil "Waldo_VehicleWeaponLoadout_TurretCatalog") exitWith {
    [missionNamespace getVariable ["Waldo_VehicleWeaponLoadout_TurretCatalog", []], missionNamespace getVariable ["Waldo_VehicleWeaponLoadout_PylonCatalog", []]]
};
if (missionNamespace getVariable ["Waldo_VehicleWeaponLoadout_CatalogBuilding", false]) exitWith {[[], []]};
missionNamespace setVariable ["Waldo_VehicleWeaponLoadout_CatalogBuilding", true];

private _startTick = diag_tickTime;

// --- Turret weapon catalog ---
private _turretRows = [];
private _seenWeapons = createHashMap;
// Walks only a class's own "Turrets" chain (never Sounds/HitPoints/animations/etc.) - the same
// structure allTurrets itself walks at runtime - recursing into nested Turrets for sub-turrets.
private _walkTurrets = {
    params ["_parentEntry"];
    private _turretsClass = _parentEntry >> "Turrets";
    if (isClass _turretsClass) then {
        {
            if (isClass _x) then {
                private _weapons = if (isArray (_x >> "weapons")) then {getArray (_x >> "weapons")} else {[]};
                if (count _weapons > 0) then {
                    private _magazines = if (isArray (_x >> "magazines")) then {getArray (_x >> "magazines")} else {[]};
                    {
                        private _weaponClass = _x;
                        if (isClass (configFile >> "CfgWeapons" >> _weaponClass) && {!(_seenWeapons getOrDefault [_weaponClass, false])}) then {
                            _seenWeapons set [_weaponClass, true];
                            private _displayName = getText (configFile >> "CfgWeapons" >> _weaponClass >> "displayName");
                            if (_displayName == "") then {_displayName = _weaponClass};
                            _turretRows pushBack [_weaponClass, _displayName, _magazines];
                        };
                    } forEach _weapons;
                };
                [_x] call _walkTurrets;
            };
        } forEach ("true" configClasses _turretsClass);
    };
};
{
    if (getNumber (_x >> "scope") >= 1) then {
        [_x] call _walkTurrets;
    };
} forEach ("true" configClasses (configFile >> "CfgVehicles"));
_turretRows = [_turretRows, [], {_x select 1}, "ASCEND"] call BIS_fnc_sortBy;

// --- Pylon ordnance catalog ---
private _pylonRows = [];
{
    private _pylonWeapon = getText (_x >> "pylonWeapon");
    if (_pylonWeapon != "") then {
        private _magazineClass = configName _x;
        private _displayName = getText (_x >> "displayName");
        if (_displayName == "") then {_displayName = _magazineClass};
        _pylonRows pushBack [_magazineClass, _displayName];
    };
} forEach ("true" configClasses (configFile >> "CfgMagazines"));
_pylonRows = [_pylonRows, [], {_x select 1}, "ASCEND"] call BIS_fnc_sortBy;

missionNamespace setVariable ["Waldo_VehicleWeaponLoadout_TurretCatalog", _turretRows];
missionNamespace setVariable ["Waldo_VehicleWeaponLoadout_PylonCatalog", _pylonRows];
missionNamespace setVariable ["Waldo_VehicleWeaponLoadout_CatalogBuilding", false];
diag_log format ["[WMP VEHWPN CATALOG] Built pack-wide catalog: %1 turret weapon(s), %2 pylon ordnance class(es), %3s.", count _turretRows, count _pylonRows, (diag_tickTime - _startTick) toFixed 2];

[_turretRows, _pylonRows]

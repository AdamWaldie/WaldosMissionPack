/*
 * Author: WaldoTheWarfighter
 * Reads a source vehicle's real, live turret weapon/magazine and pylon ordnance state and builds the
 * exact Waldo_fnc_VehicleWeaponLoadoutApply row array that would reproduce it on a target vehicle -
 * the shared read/build logic behind both Waldo_fnc_VehicleWeaponLoadoutCopy (reads and immediately
 * applies) and Waldo_fnc_VehicleWeaponLoadoutCopyPreview (reads only, for the Vehicle Customisation
 * Editor's "Copy From Nearby Vehicle" pending-row picker). Extracted into its own file so both
 * callers share one implementation instead of two copies of the same matching/quantity logic
 * drifting apart over time.
 *
 * Never mutates anything - purely reads _source/_target and returns rows. Safe to call on any
 * machine/locality; the caller decides whether to actually apply the result.
 *
 * Arguments:
 * 0: Source <OBJECT> - the vehicle to read the loadout from.
 * 1: Target <OBJECT> - the vehicle the rows would be applied onto (used only to check which turret
 *    paths/pylon count the target actually has - never modified here).
 * 2: Options <ARRAY or HASHMAP> - optional named settings: copyTurrets <BOOL> (default true),
 *    copyPylons <BOOL> (default true).
 *
 * Return Value:
 * Array [rows, copiedTurretPaths, copiedPylonIndices] - rows is a Waldo_fnc_VehicleWeaponLoadoutApply-
 * ready row array.
 *
 * Current callers: vehicleWeaponLoadoutCopy.sqf, vehicleWeaponLoadoutCopyPreview.sqf.
 *
 * Example:
 * private _built = [donorVehicle, targetVehicle] call Waldo_fnc_VehicleWeaponLoadoutCopyBuildRows;
 * _built params ["_rows", "_copiedTurretPaths", "_copiedPylonIndices"];
 */

params [
    ["_source", objNull, [objNull]],
    ["_target", objNull, [objNull]],
    ["_options", [], [[], createHashMap]]
];

if (isNull _source || {isNull _target}) exitWith {[[], [], []]};

private _optGet = {
    params ["_key", "_default"];
    if (_options isEqualType createHashMap) exitWith { _options getOrDefault [_key, _default] };
    private _row = _options select {(_x param [0, ""]) == _key};
    if (count _row > 0) then { (_row select 0) param [1, _default] } else { _default };
};
private _copyTurrets = ["copyTurrets", true] call _optGet;
private _copyPylons = ["copyPylons", true] call _optGet;

// A vehicle's horn is an ordinary CfgWeapons entry to the engine, but never a combat weapon a mission
// maker means to copy - skipping any turret whose current weapon(s) are entirely horn(s) prevents the
// most common cross-vehicle mistake this guards against: copying a source's non-combat horn turret
// onto a target path that may hold a real weapon, silently replacing it with nothing useful.
private _isHornWeapon = {
    toLower (getText (configFile >> "CfgWeapons" >> _this >> "displayName")) == "horn"
};

private _rows = [];
private _copiedTurretPaths = [];
private _copiedPylonIndices = [];

if (_copyTurrets) then {
    private _sourceTurrets = [[-1]] + (allTurrets [_source, true]);
    private _targetTurrets = [[-1]] + (allTurrets [_target, true]);
    {
        private _path = _x;
        private _weapons = _source weaponsTurret _path;
        private _isHornOnly = count _weapons > 0 && {(_weapons select {!(_x call _isHornWeapon)}) isEqualTo []};
        if (_path in _targetTurrets && {!_isHornOnly}) then {
            _copiedTurretPaths pushBack _path;
            private _rawMagazines = _source magazinesTurret _path;
            private _magazines = _rawMagazines arrayIntersect _rawMagazines;
            if (count _weapons == 0) then {
                _rows pushBack ["TURRET", _path, -1, "CLEAR", "", "", 0, 1];
            } else {
                {
                    private _weaponClass = _x;
                    private _matchingMag = _magazines select {_x in (compatibleMagazines _weaponClass)};
                    private _magForRow = if (count _matchingMag > 0) then {_matchingMag select 0} else {_magazines param [0, ""]};
                    private _magCount = if (_magForRow == "") then {0} else {
                        getNumber (configFile >> "CfgMagazines" >> _magForRow >> "count")
                    };
                    // Raw occurrence count of this exact magazine class on the source turret - the
                    // real number of separate magazine instances mounted, not just one full magazine.
                    private _magQuantity = if (_magForRow == "") then {1} else {({_x == _magForRow} count _rawMagazines) max 1};
                    _rows pushBack [
                        "TURRET", _path, -1,
                        if (_forEachIndex == 0) then {"REPLACE"} else {"ADD"},
                        _weaponClass, _magForRow, _magCount, _magQuantity
                    ];
                } forEach _weapons;
            };
        };
    } forEach _sourceTurrets;
};

if (_copyPylons) then {
    private _sourceMags = getPylonMagazines _source;
    private _targetPylonCount = count (getPylonMagazines _target);
    private _copyCount = (count _sourceMags) min _targetPylonCount;
    for "_i" from 0 to (_copyCount - 1) do {
        private _pylonIndex = _i + 1;
        _copiedPylonIndices pushBack _pylonIndex;
        private _mag = _sourceMags param [_i, ""];
        if (_mag == "") then {
            _rows pushBack ["PYLON", [-1], _pylonIndex, "CLEAR", "", "", 0];
        } else {
            // ammoOnPylon reads the source's real current ammo (not just the magazine's full config
            // count) - a battle-damaged/partially-expended source pylon copies its actual remaining
            // ammo, not a fresh reload. false (source pylon genuinely empty) is treated as 0/full.
            private _currentAmmo = _source ammoOnPylon _pylonIndex;
            if !(_currentAmmo isEqualType 0) then { _currentAmmo = 0; };
            _rows pushBack ["PYLON", [-1], _pylonIndex, "SET", "", _mag, _currentAmmo];
        };
    };
};

[_rows, _copiedTurretPaths, _copiedPylonIndices]

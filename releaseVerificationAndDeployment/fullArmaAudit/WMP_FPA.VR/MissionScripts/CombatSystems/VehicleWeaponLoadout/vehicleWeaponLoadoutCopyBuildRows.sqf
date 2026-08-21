/*
 * Author: WaldoTheWarfighter
 * Reads a source vehicle's real, live turret weapon/magazine and pylon ordnance state and builds the
 * exact Waldo_fnc_VehicleWeaponLoadoutApply row array that would reproduce it on a target vehicle -
 * the shared read/build logic behind both Waldo_fnc_VehicleWeaponLoadoutCopy (reads and immediately
 * applies) and Waldo_fnc_VehicleWeaponLoadoutCopyPreview (reads only, for the Vehicle Customisation
 * Editor's "Copy From Nearby Vehicle" pending-row picker). Extracted into its own file so both
 * callers share one implementation instead of two copies of the same matching/quantity logic
 * drifting apart over time. Turret magazines are read with magazinesAllTurrets, whose rows contain
 * the magazine classname, exact turret path, remaining ammunition and unique magazine ID. This avoids
 * treating an implementation-specific magazinesTurret string occurrence as authoritative ammo state.
 * Each live magazine is assigned only to a weapon that explicitly accepts that class.
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
    private _allLiveMagazines = magazinesAllTurrets [_source, true];
    {
        private _path = _x;
        private _weapons = _source weaponsTurret _path;
        private _isHornOnly = count _weapons > 0 && {(_weapons select {!(_x call _isHornWeapon)}) isEqualTo []};
        if (_path in _targetTurrets && {!_isHornOnly}) then {
            _copiedTurretPaths pushBack _path;
            private _pathMagazines = _allLiveMagazines select {
                (_x param [1, []]) isEqualTo _path
            };
            if (count _weapons == 0) then {
                _rows pushBack ["TURRET", _path, -1, "CLEAR", "", "", 0, 1];
            } else {
                private _firstOutputRow = true;
                private _claimedMagazineIds = [];
                {
                    private _weaponClass = _x;
                    private _compatibleClasses = ([_weaponClass] call Waldo_fnc_VehicleWeaponLoadoutMagazinesForWeapon) apply {_x select 0};
                    private _matchingEntries = _pathMagazines select {
                        private _magClass = _x param [0, ""];
                        private _magId = _x param [3, -1];
                        _magClass in _compatibleClasses && {!(_magId in _claimedMagazineIds)}
                    };
                    private _matchingClasses = (_matchingEntries apply {_x select 0}) arrayIntersect (_matchingEntries apply {_x select 0});

                    if (_matchingClasses isEqualTo []) then {
                        _rows pushBack [
                            "TURRET", _path, -1,
                            ["ADD", "REPLACE"] select _firstOutputRow,
                            _weaponClass, "", 0, 1
                        ];
                        _firstOutputRow = false;
                    } else {
                        {
                            private _magClass = _x;
                            private _instances = _matchingEntries select {(_x param [0, ""]) == _magClass};
                            private _fullCount = getNumber (configFile >> "CfgMagazines" >> _magClass >> "count");
                            private _highestLiveCount = 0;
                            {
                                _highestLiveCount = _highestLiveCount max (_x param [2, 0]);
                                _claimedMagazineIds pushBackUnique (_x param [3, -1]);
                            } forEach _instances;
                            // A copied loadout should remain usable even when the donor's currently loaded
                            // magazine is empty. Preserve its exact compatible class and number of physical
                            // magazine instances, but refill each instance to the greatest live count seen;
                            // if every instance is empty, use that class's normal full capacity.
                            private _roundsPerMagazine = if (_highestLiveCount > 0) then {_highestLiveCount} else {_fullCount max 1};
                            _rows pushBack [
                                "TURRET", _path, -1,
                                ["ADD", "REPLACE"] select _firstOutputRow,
                                _weaponClass, _magClass, _roundsPerMagazine, (count _instances) max 1
                            ];
                            _firstOutputRow = false;
                        } forEach _matchingClasses;
                    };
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

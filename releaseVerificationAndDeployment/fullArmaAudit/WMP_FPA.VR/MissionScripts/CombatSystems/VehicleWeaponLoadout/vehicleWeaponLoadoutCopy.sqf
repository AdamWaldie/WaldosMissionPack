/*
 * Author: WaldoTheWarfighter
 * Copies one vehicle's real, live turret weapon/magazine and pylon ordnance loadout onto another
 * vehicle - the strongest beginner-friendly answer to "how do I know the exact classnames": with
 * this, you never have to. Point it at a source vehicle whose armament you want and a target vehicle
 * to receive it; every classname is read directly off the source and never typed by a mission maker
 * or curator. Built entirely on top of Waldo_fnc_VehicleWeaponLoadoutApply - this function only reads
 * the source and assembles rows, the same public apply/validation path does the actual work.
 *
 * Matching rule: a turret is only copied onto a turret path that exists on both vehicles (an exact
 * path match, e.g. [0] to [0]) - there is no reliable way to infer "this vehicle's cannon corresponds
 * to that vehicle's cannon" across two different turret layouts, so mismatched vehicles simply copy
 * whatever paths genuinely line up (often none, which is reported, not silently ignored) rather than
 * guessing. Pylons are copied by index (pylon 1 to pylon 1, ...) up to however many both vehicles
 * have. A source turret/pylon with nothing mounted clears the corresponding target turret/pylon,
 * so copying is a real replace, not a merge - a stale target loadout never survives a copy. A turret
 * magazine's real quantity (how many separate magazine instances the source actually carries, not
 * just one full magazine) is preserved via the raw occurrence count in magazinesTurret.
 *
 * A source turret whose only weapon(s) are its horn (identified by CfgWeapons displayName) is skipped
 * entirely and never copied - the horn is never a combat weapon a mission maker means to copy, and the
 * matching target path could otherwise be a real weapon that would silently get overwritten with
 * nothing useful, most commonly turret [-1] on vehicles from different families.
 *
 * Arguments:
 * 0: Source <OBJECT> - the vehicle to copy the loadout from. Never modified.
 * 1: Target <OBJECT> - the vehicle to copy the loadout onto.
 * 2: Options <ARRAY or HASHMAP> - optional named settings:
 *      copyTurrets <BOOL> (default true), copyPylons <BOOL> (default true).
 *
 * Return Value:
 * Array [copiedTurretPaths, copiedPylonIndices, applyResults] - applyResults is the same
 * [[ok, detail], ...] shape Waldo_fnc_VehicleWeaponLoadoutApply returns, one entry per row it built;
 * empty array when forwarded from a client or when either vehicle argument was invalid.
 *
 * Example:
 * // Give a custom-crewed jeep the exact same turret/pylon loadout as a nearby reference vehicle:
 * [referenceVehicle, myJeep] call Waldo_fnc_VehicleWeaponLoadoutCopy;
 *
 * Current callers: mission-maker vehicle init fields, scripts, and the ZEN "Vehicle Weapon Loadout -
 * Copy From Nearby Vehicle" module (via Waldo_fnc_ZenVehicleWeaponLoadoutCopyServer).
 */

params [
    ["_source", objNull, [objNull]],
    ["_target", objNull, [objNull]],
    ["_options", [], [[], createHashMap]]
];

private _isValidVehicle = {
    !(isNull _this) && {_this isKindOf "AllVehicles"} && {!(_this isKindOf "Man")}
};
if !([_source] call _isValidVehicle && {[_target] call _isValidVehicle}) exitWith {
    diag_log "[WMP VEHWPN COPY] Waldo_fnc_VehicleWeaponLoadoutCopy called with an invalid source or target vehicle - ignored.";
    [[], [], []]
};

// Reading is safe anywhere, but the actual mutation (via Apply) is server-authoritative, so this
// itself must resolve on the server too, same as Apply - an object's Eden init field runs everywhere.
if !(isServer) exitWith {
    [_source, _target, _options] remoteExec ["Waldo_fnc_VehicleWeaponLoadoutCopy", 2];
    [[], [], []]
};

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

private _applyResults = [_target, _rows] call Waldo_fnc_VehicleWeaponLoadoutApply;
diag_log format ["[WMP VEHWPN COPY] copied %1 turret path(s) and %2 pylon(s) from %3 to %4: %5", count _copiedTurretPaths, count _copiedPylonIndices, typeOf _source, typeOf _target, _applyResults];
[_copiedTurretPaths, _copiedPylonIndices, _applyResults]

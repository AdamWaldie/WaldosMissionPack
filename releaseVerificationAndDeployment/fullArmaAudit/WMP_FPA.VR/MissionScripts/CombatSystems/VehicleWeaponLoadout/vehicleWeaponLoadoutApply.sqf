/*
 * Author: WaldoTheWarfighter
 * Adds, replaces, removes, or clears turret weapons/magazines and aircraft pylon ordnance on a
 * single vehicle. This is the main entry point for custom vehicle weapon/ammo change-out: give it a
 * vehicle and a list of change rows and it applies every row in order. Server-authoritative - calling
 * it from a client (or from an object's own Eden init field, which runs on every machine) forwards to
 * the server, which owns the actual removeWeaponTurret/addWeaponTurret/addMagazineTurret/
 * setPylonLoadOut calls. Safe to call again later on the same vehicle to make further changes; each
 * row is independent and a bad row never rolls back or blocks the rows around it.
 *
 * Arguments:
 * 0: Vehicle <OBJECT> - the vehicle to change. Any AllVehicles-derived object with turrets and/or
 *      pylons (cars, tanks, boats, static weapons, aircraft, ...) - excluding Man, which technically
 *      inherits from AllVehicles too but is out of scope for this feature (use ACE Arsenal or the
 *      loadout/logistics system for a unit's own weapons instead).
 * 1: Rows <ARRAY> - one entry per change, each:
 *      [targetType <STRING>, turretPath <ARRAY>, pylonIndex <NUMBER>, action <STRING>,
 *       weaponClass <STRING>, magazineClass <STRING>, magazineCount <NUMBER>,
 *       magazineQuantity <NUMBER> (optional, default 1, TURRET ADD/REPLACE only)]
 *      targetType: "TURRET" or "PYLON".
 *      turretPath: the turret path (e.g. [-1] for the main/driver weapon, [0], [0,0], ...) - required
 *        for TURRET rows, ignored for PYLON rows. Discover real paths with allTurrets [vehicle, true]
 *        (plus [-1], which allTurrets never includes).
 *      pylonIndex: 1-based pylon/hardpoint index - required for PYLON rows, ignored for TURRET rows.
 *        Discover the real count with count (getPylonMagazines vehicle).
 *      action for TURRET rows: "ADD" (add weaponClass, optionally load magazineClass), "REPLACE"
 *        (strip the turret's current weapons first, then ADD), "REMOVE" (take weaponClass, and
 *        magazineClass if given, off the turret without touching anything else), "CLEAR" (strip
 *        every weapon and magazine off that turret).
 *      action for PYLON rows: "SET" (equivalent aliases "ADD"/"REPLACE" also accepted - loads
 *        magazineClass onto the pylon with full ammo), "CLEAR" (empties the pylon).
 *      weaponClass: CfgWeapons class - TURRET ADD/REPLACE/REMOVE only.
 *      magazineClass: CfgMagazines class - the turret magazine to load (TURRET ADD/REPLACE, optional)
 *        or the pylon's ordnance/magazine (PYLON SET, required).
 *      magazineCount: rounds loaded INTO EACH magazine instance (optional, default: 1) - this is
 *        addMagazineTurret's own ammoCount argument, which sets how full one magazine is, not how many
 *        magazines exist. Clamped to that magazine class's own CfgMagazines "count" (a magazine can
 *        never hold more rounds than its own config allows - confirmed engine behaviour, the same
 *        clamp addMagazine itself performs); the actual clamped value is named in the row's detail
 *        text. Ignored for PYLON rows - a pylon is always explicitly loaded to its full
 *        CfgMagazines-defined ammo count via setAmmoOnPylon (setPylonLoadOut's own third argument is
 *        "forced" compatibility override, not an ammo-load flag, and never loads ammo by itself).
 *      magazineQuantity: how many separate magazine instances to add (optional, default: 1,
 *        TURRET ADD/REPLACE only) - addMagazineTurret adds exactly one magazine instance per call, so
 *        this loops it that many times to build up a real reserve ammo pool (e.g. 4 separate
 *        magazines of 30 rounds each, not one 30-round magazine). Ignored everywhere else.
 *
 * A turret whose only mounted weapon(s) are this vehicle's horn (identified by CfgWeapons
 * displayName, case-insensitive - there is no other reliable "not a combat weapon" flag) refuses
 * every TURRET action - ADD/REPLACE/REMOVE/CLEAR alike - with [false, "..."] rather than allowing it;
 * this is the single authoritative enforcement point, checked here regardless of caller, not just in
 * the ZEN "Vehicle Weapon Loadout - Configure" module's own dialog-level guard.
 *
 * Return Value:
 * Array of [ok <BOOL>, detail <STRING>] - one per input row, same order; empty array when forwarded
 * from a client or when the vehicle/rows argument was invalid.
 *
 * Example:
 * // Replace the main turret's cannon and load 6 rounds, from a vehicle's init field:
 * [this, [["TURRET", [-1], -1, "REPLACE", "arifle_MX_F", "30Rnd_65x39_caseless_mag", 6]]]
 *     call Waldo_fnc_VehicleWeaponLoadoutApply;
 * // Remove a coax MG from turret [0] (exact coax classname varies per vehicle family - confirm it
 * // with Waldo_fnc_VehicleWeaponLoadoutInspect rather than assuming "LMG_Coax" is universal) and set
 * // a jet's pylon 1 to a GBU-12 pod:
 * [this, [
 *     ["TURRET", [0], -1, "REMOVE", "LMG_Coax", "", 0],
 *     ["PYLON", [-1], 1, "SET", "", "6Rnd_GBU12_x_AGM_65E2_Pylon", 0]
 * ]] call Waldo_fnc_VehicleWeaponLoadoutApply;
 *
 * Current callers: mission-maker vehicle init fields, the ZEN "Vehicle Weapon Loadout - Configure"
 * module (via Waldo_fnc_ZenVehicleWeaponLoadoutServer). See Waldo_fnc_VehicleWeaponLoadoutInspect for
 * the beginner-friendly way to discover exact classnames from an existing vehicle.
 */

params [["_vehicle", objNull, [objNull]], ["_rows", [], [[]]]];

// "AllVehicles" alone is not vehicle-specific - Man (soldiers/AI) also inherits from it in Arma 3's
// own CfgVehicles tree (All -> AllVehicles -> Land -> Man, per the official CfgVehicles Config
// Reference), so it must be explicitly excluded or this would silently accept a placed-on-a-person
// request and try to run turret/pylon commands against a unit, which is meaningless for this feature.
if (isNull _vehicle || {!(_vehicle isKindOf "AllVehicles")} || {_vehicle isKindOf "Man"}) exitWith {
    diag_log "[WMP VEHWPN] Waldo_fnc_VehicleWeaponLoadoutApply called with an invalid vehicle - ignored.";
    []
};

// Weapon/ammo state lives on the server so JIP and every client stay in sync; an object's Eden init
// field runs everywhere, so non-server copies forward the same call, matching Waldo_fnc_Jammer.
if !(isServer) exitWith {
    [_vehicle, _rows] remoteExec ["Waldo_fnc_VehicleWeaponLoadoutApply", 2];
    []
};

private _validTurrets = [[-1]] + (allTurrets [_vehicle, true]);
private _pylonCount = count (getPylonMagazines _vehicle);
private _results = [];

// removeWeaponTurret only removes the weapon itself - confirmed against the official command page,
// it does not also drop that weapon's magazines - so a full strip needs a paired
// removeMagazinesTurret pass over whatever magazinesTurret still reports afterward, or CLEAR/REPLACE
// would leave stale magazine entries behind for a turret path that no longer has a weapon to use them.
private _stripTurret = {
    params ["_veh", "_path"];
    { _veh removeWeaponTurret [_x, _path] } forEach (_veh weaponsTurret _path);
    { _veh removeMagazinesTurret [_x, _path] } forEach (_veh magazinesTurret _path);
};

// The horn is excluded from every mutating turret operation - it is an ordinary CfgWeapons entry to
// the engine (there is no other reliable "not a combat weapon" flag), but never a weapon a mission
// maker or curator means. This is the single authoritative enforcement point: the ZEN Vehicle
// Customisation - Editor's own client-side check (vehicleCustomizationCollectTurretRow.sqf) exists
// only to avoid a wasted round-trip to the server for something that would be refused here anyway - a
// direct script call or an object's own Eden init field must be refused independently of that dialog.
private _isHornWeapon = {
    toLower (getText (configFile >> "CfgWeapons" >> _this >> "displayName")) == "horn"
};
private _isTurretHornOnly = {
    params ["_veh", "_path"];
    private _current = _veh weaponsTurret _path;
    count _current > 0 && {(_current select {!(_x call _isHornWeapon)}) isEqualTo []}
};

// [-1] (the driver/main weapon "turret") is always offered as a valid path in _validTurrets, since
// allTurrets itself never returns it - but unlike every other path in that list, allTurrets never
// confirmed it actually corresponds to a real weapon mount on this vehicle's model/config; a real
// Turrets-tree entry is inherently real because allTurrets only ever reports ones that exist. Some
// vehicles' own root CfgVehicles class declares no "weapons[]" array at all (an ordinary unarmed
// car, for instance), meaning [-1] has no physical mount point whatsoever. addWeaponTurret against a
// turret path with no real mount silently does nothing useful - no weapon actually appears or
// functions - while still reporting an ordinary-looking success, which is worse than an outright
// error for a beginner mission maker: WMP cannot create a new physical mount point on a vehicle that
// never had one, that needs model/config authoring work, not a script, so ADD/REPLACE against [-1]
// on such a vehicle is refused outright instead of silently doing nothing.
private _mainSlotHasMount = count (getArray (configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "weapons")) > 0;

{
    _x params [
        ["_targetType", "TURRET", [""]],
        ["_turretPath", [-1], [[]]],
        ["_pylonIndex", -1, [0]],
        ["_action", "ADD", [""]],
        ["_weaponClass", "", [""]],
        ["_magazineClass", "", [""]],
        ["_magazineCount", 1, [0]],
        ["_magazineQuantity", 1, [0]]
    ];
    _targetType = toUpperANSI _targetType;
    _action = toUpperANSI _action;
    private _rowOk = false;
    private _detail = "";

    if (_targetType == "TURRET") then {
        if !(_turretPath in _validTurrets) then {
            _detail = format ["Turret path %1 does not exist on %2.", _turretPath, typeOf _vehicle];
        } else {
            if ([_vehicle, _turretPath] call _isTurretHornOnly) then {
                _detail = format ["Turret %1 only carries this vehicle's horn - not a combat weapon, refused.", _turretPath];
            } else {
                switch (_action) do {
                    case "CLEAR": {
                        [_vehicle, _turretPath] call _stripTurret;
                        _rowOk = true;
                        _detail = format ["Turret %1 cleared.", _turretPath];
                    };
                    case "REMOVE": {
                        if (_weaponClass != "" && {_weaponClass in (_vehicle weaponsTurret _turretPath)}) then {
                            _vehicle removeWeaponTurret [_weaponClass, _turretPath];
                            if (_magazineClass != "") then { _vehicle removeMagazinesTurret [_magazineClass, _turretPath]; };
                            _rowOk = true;
                            _detail = format ["Removed %1 from turret %2.", _weaponClass, _turretPath];
                        } else {
                            _detail = format ["%1 is not currently mounted on turret %2.", _weaponClass, _turretPath];
                        };
                    };
                    case "ADD"; case "REPLACE": {
                        if !(isClass (configFile >> "CfgWeapons" >> _weaponClass)) then {
                            _detail = format ["Unknown weapon class: %1", _weaponClass];
                        } else {
                            if (_turretPath isEqualTo [-1] && {!_mainSlotHasMount}) then {
                                _detail = format ["Turret [-1] has no weapon mount in %1's own model/config - WMP cannot create one, that needs model/config authoring work. Pick a real turret path from allTurrets instead, or a vehicle whose class already declares a driver/main weapon.", typeOf _vehicle];
                            } else {
                                if (_action == "REPLACE") then {
                                    [_vehicle, _turretPath] call _stripTurret;
                                };
                                // Copy can legitimately emit more than one magazine-class row for the
                                // same multi-ammunition weapon. Do not add a duplicate weapon entry when
                                // a later row is only loading another compatible magazine class.
                                if !(_weaponClass in (_vehicle weaponsTurret _turretPath)) then {
                                    _vehicle addWeaponTurret [_weaponClass, _turretPath];
                                };
                                _detail = format ["%1 %2 on turret %3.", ["Added", "Replaced with"] select (_action == "REPLACE"), _weaponClass, _turretPath];
                                if (_magazineClass != "") then {
                                    if !(isClass (configFile >> "CfgMagazines" >> _magazineClass)) then {
                                        _detail = _detail + format [" Magazine class %1 is unknown - no ammo loaded.", _magazineClass];
                                    } else {
                                        // compatibleMagazines is muzzle-aware (a weapon can have more than one
                                        // muzzle, e.g. a rifle plus an underslung GL) and this row doesn't ask
                                        // the mission maker which muzzle they mean, so a mismatch here is only
                                        // ever logged as a heads-up, never a hard rejection.
                                        if !(_magazineClass in (compatibleMagazines _weaponClass)) then {
                                            diag_log format ["[WMP VEHWPN] note: %1 is not a documented compatible magazine for %2's primary muzzle on %3 (a secondary muzzle can still be valid) - loading it anyway.", _magazineClass, _weaponClass, typeOf _vehicle];
                                        };
                                        // A magazine instance cannot hold more rounds than its own CfgMagazines
                                        // "count" - the engine itself clamps addMagazineTurret's ammoCount to
                                        // that maximum (same behaviour as addMagazine), same as this row's own
                                        // PYLON ammo handling already does explicitly. Clamped here too, rather
                                        // than silently relying on the undocumented engine clamp, so the
                                        // reported detail always names the rounds actually loaded.
                                        private _magFullCount = getNumber (configFile >> "CfgMagazines" >> _magazineClass >> "count");
                                        private _roundsPerMag = if (_magFullCount > 0) then {(_magazineCount max 1) min _magFullCount} else {_magazineCount max 1};
                                        // addMagazineTurret adds exactly ONE magazine instance per call, loaded
                                        // to _roundsPerMag rounds - calling it _magazineQuantity times builds a
                                        // real multi-magazine reserve rather than one oversized magazine.
                                        for "_m" from 1 to (_magazineQuantity max 1) do {
                                            _vehicle addMagazineTurret [_magazineClass, _turretPath, _roundsPerMag];
                                        };
                                        // Read back the authoritative engine state instead of declaring
                                        // success because the commands were issued. magazinesAllTurrets
                                        // exposes the exact turret path, class, remaining rounds and unique
                                        // magazine ID, so it catches both a missing magazine and the observed
                                        // zero-ammo replacement regression.
                                        private _readBack = (magazinesAllTurrets [_vehicle, true]) select {
                                            (_x param [0, ""]) == _magazineClass
                                            && {(_x param [1, []]) isEqualTo _turretPath}
                                        };
                                        private _liveReadBack = _readBack select {(_x param [2, 0]) > 0};
                                        if !(_weaponClass in (_vehicle weaponsTurret _turretPath)) then {
                                            _detail = _detail + " Engine read-back did not find the requested weapon.";
                                        } else {
                                            if (_liveReadBack isEqualTo []) then {
                                                _detail = _detail + format [" Engine read-back found no loaded %1 ammunition; the row failed rather than reporting a false success.", _magazineClass];
                                            } else {
                                                private _actualRounds = 0;
                                                {_actualRounds = _actualRounds + (_x param [2, 0]);} forEach _liveReadBack;
                                                _detail = _detail + format [" Loaded %1x magazine(s) of %2 (%3/%4 requested; %5 live round(s) read back).", _magazineQuantity max 1, _magazineClass, _roundsPerMag, _magFullCount, _actualRounds];
                                            };
                                        };
                                    };
                                };
                                private _weaponApplied = _weaponClass in (_vehicle weaponsTurret _turretPath);
                                private _ammoApplied = _magazineClass == "" || {
                                    count ((magazinesAllTurrets [_vehicle, true]) select {
                                        (_x param [0, ""]) == _magazineClass
                                        && {(_x param [1, []]) isEqualTo _turretPath}
                                        && {(_x param [2, 0]) > 0}
                                    }) > 0
                                };
                                _rowOk = _weaponApplied && _ammoApplied;
                                if (_rowOk && {_action == "REPLACE"}) then {
                                    private _turretOwner = _vehicle turretOwner _turretPath;
                                    if (_turretOwner <= 0) then {_turretOwner = owner _vehicle;};
                                    if (_turretOwner <= 0) then {_turretOwner = 2;};
                                    [_vehicle, _turretPath, _weaponClass, _magazineClass] remoteExecCall [
                                        "Waldo_fnc_VehicleWeaponLoadoutSelectLocal",
                                        _turretOwner
                                    ];
                                };
                            };
                        };
                    };
                    default { _detail = format ["Unknown turret action: %1", _action]; };
                };
            };
        };
    } else {
        if (_targetType == "PYLON") then {
            if (_pylonIndex < 1 || {_pylonIndex > _pylonCount}) then {
                _detail = format ["Pylon %1 does not exist on %2 (%3 pylon(s)).", _pylonIndex, typeOf _vehicle, _pylonCount];
            } else {
                switch (_action) do {
                    case "CLEAR": {
                        _vehicle setPylonLoadOut [_pylonIndex, "", true];
                        _rowOk = true;
                        _detail = format ["Pylon %1 cleared.", _pylonIndex];
                    };
                    case "SET"; case "ADD"; case "REPLACE": {
                        if !(isClass (configFile >> "CfgMagazines" >> _magazineClass)) then {
                            _detail = format ["Unknown pylon magazine/ordnance class: %1", _magazineClass];
                        } else {
                            // setPylonLoadOut's third argument is "forced" (bypass the pylon's own
                            // compatibility check), NOT an ammo-load flag - confirmed against the
                            // official command page, not assumed. It never loads ammo by itself, so
                            // a fresh assignment needs an explicit setAmmoOnPylon call to actually
                            // arm the pylon - the exact pairing VVD's own restore code already uses
                            // (VVDOpen.sqf lines 987-988/1316-1317), which this now matches.
                            // magazineCount doubles as the exact pylon ammo count here: 0 (or
                            // omitted) means "full", matching the previous always-full behaviour for
                            // any existing caller that never set it; a positive value loads exactly
                            // that many rounds, clamped so a mission maker can't ask for more than the
                            // ordnance's own CfgMagazines "count" actually holds.
                            private _fullAmmo = getNumber (configFile >> "CfgMagazines" >> _magazineClass >> "count");
                            private _ammoToLoad = if (_magazineCount > 0) then {_magazineCount min _fullAmmo} else {_fullAmmo};
                            _vehicle setPylonLoadOut [_pylonIndex, _magazineClass, true];
                            _vehicle setAmmoOnPylon [_pylonIndex, _ammoToLoad];
                            _rowOk = true;
                            _detail = format ["Pylon %1 set to %2 (%3/%4 ammo).", _pylonIndex, _magazineClass, _ammoToLoad, _fullAmmo];
                        };
                    };
                    default { _detail = format ["Unknown pylon action: %1", _action]; };
                };
            };
        } else {
            _detail = format ["Unknown target type: %1", _targetType];
        };
    };

    _results pushBack [_rowOk, _detail];
} forEach _rows;

diag_log format ["[WMP VEHWPN] applied %1 row(s) to %2 (%3 ok): %4", count _rows, typeOf _vehicle, {_x select 0} count _results, _results];
_results

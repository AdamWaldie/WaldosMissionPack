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
 *      pylons (cars, tanks, boats, static weapons, aircraft, ...).
 * 1: Rows <ARRAY> - one entry per change, each:
 *      [targetType <STRING>, turretPath <ARRAY>, pylonIndex <NUMBER>, action <STRING>,
 *       weaponClass <STRING>, magazineClass <STRING>, magazineCount <NUMBER>]
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
 *      magazineCount: rounds loaded for a TURRET magazine (optional, default: 1). Ignored for PYLON
 *        rows - setPylonLoadOut always loads a pylon to its full config-defined ammo.
 *
 * Return Value:
 * Array of [ok <BOOL>, detail <STRING>] - one per input row, same order; empty array when forwarded
 * from a client or when the vehicle/rows argument was invalid.
 *
 * Example:
 * // Replace the main turret's cannon and load 6 rounds, from a vehicle's init field:
 * [this, [["TURRET", [-1], -1, "REPLACE", "arifle_MX_F", "30Rnd_65x39_caseless_mag", 6]]]
 *     call Waldo_fnc_VehicleWeaponLoadoutApply;
 * // Remove a coax MG from turret [0] and set a jet's pylon 1 to a GBU-12 pod:
 * [this, [
 *     ["TURRET", [0], -1, "REMOVE", "LMG_Coax", "", 0],
 *     ["PYLON", [-1], 1, "SET", "", "6Rnd_GBU12_x_AGM_65E2_Pylon", 0]
 * ]] call Waldo_fnc_VehicleWeaponLoadoutApply;
 *
 * Current callers: mission-maker vehicle init fields, the ZEN "Vehicle Weapon Loadout - Configure"
 * module (via Waldo_fnc_ZenVehicleWeaponLoadoutServer).
 */

params [["_vehicle", objNull, [objNull]], ["_rows", [], [[]]]];

if (isNull _vehicle || {!(_vehicle isKindOf "AllVehicles")}) exitWith {
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

{
    _x params [
        ["_targetType", "TURRET", [""]],
        ["_turretPath", [-1], [[]]],
        ["_pylonIndex", -1, [0]],
        ["_action", "ADD", [""]],
        ["_weaponClass", "", [""]],
        ["_magazineClass", "", [""]],
        ["_magazineCount", 1, [0]]
    ];
    _targetType = toUpperANSI _targetType;
    _action = toUpperANSI _action;
    private _rowOk = false;
    private _detail = "";

    if (_targetType == "TURRET") then {
        if !(_turretPath in _validTurrets) then {
            _detail = format ["Turret path %1 does not exist on %2.", _turretPath, typeOf _vehicle];
        } else {
            switch (_action) do {
                case "CLEAR": {
                    { _vehicle removeWeaponTurret [_x, _turretPath] } forEach (_vehicle weaponsTurret _turretPath);
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
                        if (_action == "REPLACE") then {
                            { _vehicle removeWeaponTurret [_x, _turretPath] } forEach (_vehicle weaponsTurret _turretPath);
                        };
                        _vehicle addWeaponTurret [_weaponClass, _turretPath];
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
                                _vehicle addMagazineTurret [_magazineClass, _turretPath, _magazineCount max 1];
                                _detail = _detail + format [" Loaded %1x %2.", _magazineCount max 1, _magazineClass];
                            };
                        };
                        _rowOk = true;
                    };
                };
                default { _detail = format ["Unknown turret action: %1", _action]; };
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
                            // The third argument (true) loads the pylon to its full config-defined
                            // ammo count - the same call shape VVD's own purge/restore code already
                            // uses (VVDOpen.sqf), so this is a proven, not assumed, pattern.
                            _vehicle setPylonLoadOut [_pylonIndex, _magazineClass, true];
                            _rowOk = true;
                            _detail = format ["Pylon %1 set to %2.", _pylonIndex, _magazineClass];
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

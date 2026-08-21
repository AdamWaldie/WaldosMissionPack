/*
 * Author: WaldoTheWarfighter
 * Copies one vehicle's real, live turret weapon/magazine and pylon ordnance loadout onto another
 * vehicle - the strongest beginner-friendly answer to "how do I know the exact classnames": with
 * this, you never have to. Point it at a source vehicle whose armament you want and a target vehicle
 * to receive it; every classname is read directly off the source and never typed by a mission maker
 * or curator. Reads and row-building are shared with Waldo_fnc_VehicleWeaponLoadoutCopyPreview via
 * Waldo_fnc_VehicleWeaponLoadoutCopyBuildRows; this function applies the built rows immediately via
 * Waldo_fnc_VehicleWeaponLoadoutApply, which does the actual validation/mutation work.
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
 * Current callers: mission-maker vehicle init fields, scripts, and the ZEN "Vehicle Customisation -
 * Editor" module's "Copy From Nearby Vehicle" action (via Waldo_fnc_ZenVehicleCustomizationServer).
 */

params [
    ["_source", objNull, [objNull]],
    ["_target", objNull, [objNull]],
    ["_options", [], [[], createHashMap]]
];

private _isValidVehicle = {
    !(isNull _this) && {_this isKindOf "AllVehicles"} && {!(_this isKindOf "Man")}
};
if !(_source call _isValidVehicle && {_target call _isValidVehicle}) exitWith {
    diag_log "[WMP VEHWPN COPY] Waldo_fnc_VehicleWeaponLoadoutCopy called with an invalid source or target vehicle - ignored.";
    [[], [], []]
};

// Reading is safe anywhere, but the actual mutation (via Apply) is server-authoritative, so this
// itself must resolve on the server too, same as Apply - an object's Eden init field runs everywhere.
if !(isServer) exitWith {
    [_source, _target, _options] remoteExec ["Waldo_fnc_VehicleWeaponLoadoutCopy", 2];
    [[], [], []]
};

private _built = [_source, _target, _options] call Waldo_fnc_VehicleWeaponLoadoutCopyBuildRows;
_built params ["_rows", "_copiedTurretPaths", "_copiedPylonIndices"];

private _applyResults = [_target, _rows] call Waldo_fnc_VehicleWeaponLoadoutApply;
diag_log format ["[WMP VEHWPN COPY] copied %1 turret path(s) and %2 pylon(s) from %3 to %4: %5", count _copiedTurretPaths, count _copiedPylonIndices, typeOf _source, typeOf _target, _applyResults];
[_copiedTurretPaths, _copiedPylonIndices, _applyResults]

/*
 * Author: WaldoTheWarfighter
 * Finalises a replaced turret weapon on the machine that owns that exact turret. Selecting and
 * loading a newly re-added weapon is locality-sensitive even though addWeaponTurret and
 * addMagazineTurret have global effects. Without this final local step, Arma can leave the turret's
 * old/removed muzzle selected and present the replacement as having zero usable ammunition until a
 * gunner manually changes weapon. Repeat-safe: selecting and loading the same weapon/magazine again
 * only reasserts the intended active weapon.
 *
 * Arguments:
 * 0: Vehicle <OBJECT> - vehicle whose turret weapon was replaced.
 * 1: Turret path <ARRAY> - exact turret path, e.g. [0] or [0,0].
 * 2: Weapon classname <STRING> - newly installed CfgWeapons class.
 * 3: Magazine classname <STRING> - compatible magazine to load; empty string skips loadMagazine.
 *
 * Return Value: BOOL - true when executed on the turret owner and the weapon exists, otherwise false.
 *
 * Current caller: Waldo_fnc_VehicleWeaponLoadoutApply after a successful REPLACE row; it is remotely
 * executed on `vehicle turretOwner turretPath`, including after locality changes to a player or HC.
 *
 * Example:
 * [vehicle, [0], "autocannon_40mm_CTWS", "60Rnd_40mm_GPR_Tracer_Red_shells"]
 *     call Waldo_fnc_VehicleWeaponLoadoutSelectLocal;
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_turretPath", [], [[]]],
    ["_weaponClass", "", [""]],
    ["_magazineClass", "", [""]]
];

if (isNull _vehicle || {_turretPath isEqualTo []} || {_weaponClass == ""}) exitWith {false};
if !(_vehicle turretLocal _turretPath) exitWith {
    diag_log format ["[WMP VEHWPN] local selection skipped: turret %1 on %2 is not local to owner %3.", _turretPath, typeOf _vehicle, clientOwner];
    false
};
if !(_weaponClass in (_vehicle weaponsTurret _turretPath)) exitWith {false};

_vehicle selectWeaponTurret [_weaponClass, _turretPath];
if (_magazineClass != "" && {!isNull (_vehicle turretUnit _turretPath)}) then {
    _vehicle loadMagazine [_turretPath, _weaponClass, _magazineClass];
};
true

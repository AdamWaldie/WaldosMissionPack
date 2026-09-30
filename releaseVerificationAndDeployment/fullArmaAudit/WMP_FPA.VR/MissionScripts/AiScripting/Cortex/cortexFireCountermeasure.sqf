/*
 * Author: WaldoTheWarfighter
 * Fires a vehicle's countermeasure launcher: smoke on ground vehicles, flares on aircraft.
 *
 * Vanilla and most mod smoke launchers and flare launchers use the "cmlauncher" weapon simulation,
 * so the launcher is found from config rather than by name. Turrets are searched driver first, then
 * every turret, including person-turret paths: modded operational turrets may use that flag.
 * Seat protection is handled separately by passenger eligibility. Live inventory is inspected only when a countermeasure is requested: different
 * loadouts of the same class and initially empty turrets must not share stale results. BIS_fnc_fire requests the weapon
 * from its own turret.
 * Locality and authority: call where the vehicle is local.
 *
 * Review contract: A nonlocal vehicle is rejected. This helper has no persistent side effects or JIP installation; callers own repetition and cooldown.
 *
 * Arguments:
 * 0: vehicle <OBJECT>
 *
 * Return Value:
 * Boolean - true when a launcher firing request was dispatched; Fired events establish actual fire
 *
 * Example:
 * [_vehicle] call Waldo_fnc_CortexFireCountermeasure;
 * Result: a damaged APC pops its smoke screen before withdrawing.
 *
 * Current callers: Waldo_fnc_CortexVehicles and the aircraft flare handler in Waldo_fnc_CortexDiscover.
 */

params [["_vehicle", objNull, [objNull]]];
if (isNull _vehicle || {!alive _vehicle} || {!local _vehicle}) exitWith {false};
private _entry = ["", []];
{
    private _turret = _x;
    private _weapons = _vehicle weaponsTurret _turret;
    private _index = _weapons findIf {toLowerANSI (getText (configFile >> "CfgWeapons" >> _x >> "simulation")) == "cmlauncher"};
    if (_index >= 0) exitWith {_entry = [_weapons select _index, _turret]};
} forEach ([[-1]] + allTurrets [_vehicle, true]);
_entry params ["_weapon", "_turret"];
if (_weapon == "") exitWith {false};
[_vehicle, _weapon, _turret] call BIS_fnc_fire;
true

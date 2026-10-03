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
 * Current callers: Waldo_fnc_CortexVehicles, Waldo_fnc_CortexAirAttack and the aircraft flare
 * handler in Waldo_fnc_CortexDiscover.
 */

params [["_vehicle", objNull, [objNull]]];
if (isNull _vehicle || {!alive _vehicle} || {!local _vehicle}) exitWith {false};
private _entry = ["", []];
{
    private _turret = _x;
    private _weapons = _vehicle weaponsTurret _turret;
    private _turretMagazines=(magazinesAllTurrets _vehicle) select {(_x select 1) isEqualTo _turret && {(_x select 2) > 0}};
    private _index = _weapons findIf {
        private _weapon=_x;
        toLowerANSI (getText (configFile >> "CfgWeapons" >> _weapon >> "simulation")) == "cmlauncher"
            && {_turretMagazines findIf {(_x select 0) in compatibleMagazines _weapon} >= 0}
    };
    if (_index >= 0) exitWith {_entry = [_weapons select _index, _turret]};
} forEach ([[-1]] + allTurrets [_vehicle, true]);
_entry params ["_weapon", "_turret"];
if (_weapon == "") exitWith {_vehicle setVariable ["Waldo_Cortex_CountermeasureLastRequest",[serverTime,false,"NO_AMMO_OR_LAUNCHER"],true]; false};
[_vehicle, _weapon, _turret] call BIS_fnc_fire;
_vehicle setVariable ["Waldo_Cortex_CountermeasureLastRequest",[serverTime,true,_weapon,_turret],true];
true

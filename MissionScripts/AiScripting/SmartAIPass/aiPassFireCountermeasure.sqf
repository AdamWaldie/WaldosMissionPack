/*
 * Author: WaldoTheWarfighter
 * Fires a vehicle's countermeasure launcher: smoke on ground vehicles, flares on aircraft.
 *
 * Vanilla and most mod smoke launchers and flare launchers use the "cmlauncher" weapon simulation,
 * so the launcher is found from config rather than by name. Turrets are searched driver first, then
 * every turret. Results are cached per vehicle class on this machine. BIS_fnc_fire fires the weapon
 * from its own turret.
 * Locality and authority: call where the vehicle is local.
 *
 * Review contract: A nonlocal vehicle is rejected. This helper has no persistent side effects or JIP installation; callers own repetition and cooldown.
 *
 * Arguments:
 * 0: vehicle <OBJECT>
 *
 * Return Value:
 * Boolean - true when a countermeasure was fired
 *
 * Example:
 * [_vehicle] call Waldo_fnc_AIPassFireCountermeasure;
 * Result: a damaged APC pops its smoke screen before withdrawing.
 *
 * Current callers: Waldo_fnc_AIPassVehicles and the aircraft flare handler in Waldo_fnc_AIPassDiscover.
 */

params [["_vehicle", objNull, [objNull]]];
if (isNull _vehicle || {!alive _vehicle} || {!local _vehicle}) exitWith {false};
private _cache = missionNamespace getVariable ["Waldo_AIPass_CountermeasureCache", createHashMap];
private _entry = _cache getOrDefault [typeOf _vehicle, []];
if (_entry isEqualTo []) then {
    _entry = ["", []];
    {
        private _turret = _x;
        private _weapons = _vehicle weaponsTurret _turret;
        private _index = _weapons findIf {getText (configFile >> "CfgWeapons" >> _x >> "simulation") == "cmlauncher"};
        if (_index >= 0) exitWith {_entry = [_weapons select _index, _turret]};
    } forEach ([[-1]] + allTurrets [_vehicle, false]);
    _cache set [typeOf _vehicle, _entry];
    missionNamespace setVariable ["Waldo_AIPass_CountermeasureCache", _cache];
};
_entry params ["_weapon", "_turret"];
if (_weapon == "") exitWith {false};
[_vehicle, _weapon, _turret] call BIS_fnc_fire;
true

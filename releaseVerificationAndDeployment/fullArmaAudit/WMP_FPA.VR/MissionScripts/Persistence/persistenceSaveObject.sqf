/*
 * Author: Waldo
 * Saves one registered object's selected state fields to INIDBI2.
 *
 * Arguments:
 * 0: object <OBJECT>
 * 1: key <STRING>
 * 2: options <ARRAY> - cargo, damage, fuel, ammo/pylons, position, custom variable names
 *
 * Return Value:
 * Boolean - true when written
 *
 * Example:
 * [_crate, "base_supply_1", [true, false, false, false, false]] call Waldo_fnc_PersistenceSaveObject;
 */

params ["_object", "_key", "_options"];
if !(isServer) exitWith {false};
if (remoteExecutedOwner > 0) exitWith {false};
if (isNull _object || {!(missionNamespace getVariable ["Waldo_Persistence_Active", false])}) exitWith {false};

_options params ["_saveCargo", "_saveDamage", "_saveFuel", "_saveAmmo", "_savePosition"];
private _databaseName = missionNamespace getVariable ["Waldo_Persistence_DatabaseName", "WaldosMissionPack"];
private _safeDatabaseName = [_databaseName, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
if (_safeDatabaseName == "") then {_safeDatabaseName = "WaldosMissionPack"};
private _db = ["new", format ["%1_OBJECT_%2", _safeDatabaseName, _key]] call OO_INIDBI;
private _cargo = if (_saveCargo) then {
    [getItemCargo _object, getWeaponCargo _object, getMagazineCargo _object, getBackpackCargo _object]
} else {[]};
private _damage = if (_saveDamage) then {getAllHitPointsDamage _object} else {[]};
private _fuel = if (_saveFuel && {_object isKindOf "AllVehicles"}) then {fuel _object} else {-1};
private _ammo = if (_saveAmmo && {_object isKindOf "AllVehicles"}) then {magazinesAllTurrets _object} else {[]};
private _pylons = if (_saveAmmo && {_object isKindOf "AllVehicles"}) then {getAllPylonsInfo _object} else {[]};
private _position = if (_savePosition) then {[getPosATL _object, [vectorDir _object, vectorUp _object]]} else {[]};
private _custom = [];
{
    private _value = _object getVariable [_x, nil];
    if !(isNil "_value") then {_custom pushBack [_x, _value]};
} forEach (_options param [5, missionNamespace getVariable ["Waldo_Persistence_DefaultCustomVariables", []]]);
private _state = [2, typeOf _object, _cargo, _damage, _fuel, _ammo, _pylons, _position, _custom];

["write", ["WMP", "ObjectState", _state]] call _db;
true

/*
 * Author: WaldoTheWarfighter
 * Restores one registered object's selected state fields from INIDBI2.
 *
 * Arguments:
 * 0: object <OBJECT>
 * 1: key <STRING>
 * 2: options <ARRAY> - cargo, damage, fuel, ammo/pylons, position, custom variable names
 *
 * Return Value:
 * Boolean - true when a compatible state was restored
 *
 * Example:
 * [_crate, "base_supply_1", [true, false, false, false, false]] call Waldo_fnc_PersistenceLoadObject;
 */

params ["_object", "_key", "_options"];
if !(isServer) exitWith {false};
if (remoteExecutedOwner > 0) exitWith {false};
if (isNull _object || {!(missionNamespace getVariable ["Waldo_Persistence_Active", false])}) exitWith {false};

private _databaseName = missionNamespace getVariable ["Waldo_Persistence_DatabaseName", "WaldosMissionPack"];
private _safeDatabaseName = [_databaseName, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
if (_safeDatabaseName == "") then {_safeDatabaseName = "WaldosMissionPack"};
private _db = ["new", format ["%1_OBJECT_%2", _safeDatabaseName, _key]] call OO_INIDBI;
private _state = ["read", ["WMP", "ObjectState", []]] call _db;
if (count _state < 8) exitWith {false};

_state params ["_version", "_className", "_cargo", "_damage", "_fuel", "_ammo", "_pylons", "_position", ["_custom", []]];
if (!(_version in [1, 2]) || {_className != typeOf _object}) exitWith {
    diag_log format ["[WMP PERSISTENCE] Object '%1' state ignored because its class changed from %2 to %3.", _key, _className, typeOf _object];
    false
};
_options params ["_loadCargo", "_loadDamage", "_loadFuel", "_loadAmmo", "_loadPosition"];

if (_loadCargo && {count _cargo >= 4}) then {
    clearItemCargoGlobal _object;
    clearWeaponCargoGlobal _object;
    clearMagazineCargoGlobal _object;
    clearBackpackCargoGlobal _object;
    {
        _x params ["_classes", "_counts"];
        private _kind = _forEachIndex;
        {
            private _count = _counts select _forEachIndex;
            switch (_kind) do {
                case 0: {_object addItemCargoGlobal [_x, _count]};
                case 1: {_object addWeaponCargoGlobal [_x, _count]};
                case 2: {_object addMagazineCargoGlobal [_x, _count]};
                case 3: {_object addBackpackCargoGlobal [_x, _count]};
            };
        } forEach _classes;
    } forEach _cargo;
};
if (_loadDamage && {count _damage >= 3}) then {
    private _names = _damage select 0;
    private _values = _damage select 2;
    {_object setHitPointDamage [_x, _values select _forEachIndex]} forEach _names;
};
if (_loadFuel && {_fuel >= 0}) then {_object setFuel _fuel};
if (_loadAmmo && {count _ammo > 0}) then {
    private _turrets = [];
    {_turrets pushBackUnique (_x select 1)} forEach magazinesAllTurrets _object;
    {_object removeAllMagazinesTurret _x} forEach _turrets;
    {_object addMagazineTurret [_x select 0, _x select 1, _x select 2]} forEach _ammo;
    {
        _object setPylonLoadout [_x select 0, _x select 3, true, _x select 2];
        _object setAmmoOnPylon [_x select 0, _x select 4];
    } forEach _pylons;
};
if (_loadPosition && {count _position >= 2}) then {
    _object setPosATL (_position select 0);
    _object setVectorDirAndUp (_position select 1);
};
private _allowedCustom = _options param [5, missionNamespace getVariable ["Waldo_Persistence_DefaultCustomVariables", []]];
{
    _x params ["_name", "_value"];
    if (_name in _allowedCustom) then {_object setVariable [_name, _value, true]};
} forEach _custom;
if ("Waldo_ObjectScale" in _allowedCustom) then {
    _object setObjectScale (_object getVariable ["Waldo_ObjectScale", 1]);
};

true

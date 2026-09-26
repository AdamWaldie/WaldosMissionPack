/*
 * Author: WaldoTheWarfighter
 * Restores recorded formation, attack permission, vehicle speed and unload settings; cancels only follower paths.
 * Locality/authority: server owns registration; driving commands execute only on current owners.
 * Repeat/JIP: ordered registry snapshots replace old settings; owner-local paths rebuild on migration.
 * Arguments: 0: group <GROUP>, grpNull; 1: forget baseline <BOOL>, true.
 * Return Value: Nothing.
 * Current callers: ConvoySync and ConvoyTick.
 * Example: [convoyGroup] call Waldo_fnc_ConvoyReleaseLocal;
 */
params [["_group", grpNull, [grpNull]], ["_forget", true, [true]]];
if (!local _group) exitWith {};
private _restore = _group getVariable ["Waldo_Convoy_Restore", []];
if (_restore isNotEqualTo []) then {
    _restore params ["_formation", "_attack", "_vehicles"];
    if (formation _group == "COLUMN") then {_group setFormation _formation};
    _group enableAttack _attack;
    {
        _x params ["_vehicle", "_speed", "_unload"];
        if (local _vehicle) then {
            _vehicle forceSpeed _speed;
            _vehicle setUnloadInCombat _unload;
            private _driver = driver _vehicle;
            if (!isNull _driver && {!isPlayer _driver} && {local _driver} && {_driver != leader _group}) then {_driver doFollow leader _group};
        };
    } forEach _vehicles;
};
_group setVariable ["Waldo_Convoy_LocalState", nil];
if (_forget) then {_group setVariable ["Waldo_Convoy_Restore", nil, true]};

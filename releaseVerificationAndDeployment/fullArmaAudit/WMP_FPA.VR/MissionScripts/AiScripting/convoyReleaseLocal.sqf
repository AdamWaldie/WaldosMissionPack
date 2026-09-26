/*
 * Author: WaldoTheWarfighter
 * Restores recorded formation, attack permission, vehicle speed and unload settings; cancels only follower paths.
 * Locality/authority: server owns registration; driving commands execute only on current owners.
 * Repeat/JIP: ordered registry snapshots replace old settings; owner-local paths rebuild on migration.
 * Arguments: 0: group <GROUP>, grpNull; 1: forget baseline <BOOL>, true; 2: baseline <ARRAY>, [] reads the locally received baseline; 3: still-controlled vehicles <ARRAY>, [].
 * Return Value: Nothing.
 * Current callers: ConvoySync and ConvoyTick.
 * Example: [convoyGroup] call Waldo_fnc_ConvoyReleaseLocal;
 */
params [["_group", grpNull, [grpNull]], ["_forget", true, [true]], ["_restore", [], [[]]], ["_keepCrew", [], [[]]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {};
if (_restore isEqualTo []) then {_restore = _group getVariable ["Waldo_Convoy_Restore", []]};
if (_restore isNotEqualTo []) then {
    _restore params ["_formation", "_attack", "_vehicles"];
    if (local _group) then {
        if (formation _group == "COLUMN") then {_group setFormation _formation};
        _group enableAttack _attack;
    };
    {
        _x params ["_vehicle", "_speed", "_unload"];
        if (_forget && {isServer} && {!(_vehicle in _keepCrew)} && {(_vehicle getVariable ["Waldo_Convoy_Group", grpNull]) == _group}) then {
            _vehicle setVariable ["Waldo_Convoy_Group", nil, true];
            _vehicle setVariable ["Waldo_Convoy_Active", nil, true];
        };
        {
            private _unit = _x;
            private _target = _unit getVariable ["Waldo_Convoy_Target", objNull];
            if (local _unit && {!isPlayer _unit} && {!isNull _target}) then {
                if (assignedTarget _unit == _target) then {_unit doTarget objNull};
                _unit setVariable ["Waldo_Convoy_Target", nil];
            };
        } forEach crew _vehicle;
        if !(_vehicle in _keepCrew) then {
            private _hitEH = _vehicle getVariable ["Waldo_Convoy_HitEH", -1];
            if (_hitEH >= 0) then {_vehicle removeEventHandler ["Hit", _hitEH]};
            _vehicle setVariable ["Waldo_Convoy_HitEH", nil];
        };
        if (local _vehicle) then {
            _vehicle forceSpeed _speed;
            if !(_vehicle in _keepCrew) then {_vehicle setUnloadInCombat _unload;};
            private _driver = driver _vehicle;
            if (!isNull _driver && {!isPlayer _driver} && {local _driver} && {_driver != leader _group}) then {_driver doFollow leader _group};
        };
    } forEach _vehicles;
};
_group setVariable ["Waldo_Convoy_LocalState", nil];
if (_forget) then {_group setVariable ["Waldo_Convoy_Restore", nil]};

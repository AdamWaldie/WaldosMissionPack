/*
 * Author: Waldo
 * Virtual Vehicle Depot helper - applies configured hitpoint damage to a spawned depot vehicle after
 * an optional random delay window. Part of the WIP Virtual Vehicle Depot. Registered as
 * Waldo_fnc_VVDVehicleDamage.
 *
 * Arguments:
 * 0: _veh <OBJECT> - the vehicle to damage
 * 1: _hitpointsDamage <ARRAY> - [hitpoint, damage] pairs to apply
 * 2: _damageDelays <ARRAY> - [minDelay, maxDelay] seconds before applying
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_veh, [["HitEngine", 0.5]], [0, 5]] call Waldo_fnc_VVDVehicleDamage;
 */

params["_veh", "_hitpointsDamage", "_damageDelays"];

_damageDelayMin = _damageDelays select 0;
_damageDelayMax = _damageDelays select 1;

_delay = 0;

if (_damageDelayMin != 0 || _damageDelayMax != 0) then {
    if (_damageDelayMax < _damageDelayMin) then {
        _delay = _damageDelayMin;
    } else {
        _delay = _damageDelayMin + random (_damageDelayMax - _damageDelayMin);
    };
};

_timeEnd = time + _delay;
_interval = [_delay, 10] select (_delay > 10);

while {true} do {
    _time = time;

    if (isNull _veh) exitWith {};

    if (_time >= _timeEnd) exitWith {
        _allHitpoints = getAllHitPointsDamage _veh;
        if ((count _allHitpoints) != 0) then {
            _hitpointNames = _allHitpoints select 0;
            {
                _veh setHitPointDamage [_hitpointNames select _forEachIndex, _hitpointsDamage select _forEachIndex];
            } forEach _hitpointNames;
        };
    };

    if (_interval == 10 && _time + _interval > _timeEnd) then {
        _interval = _timeEnd - _time;
    };

    sleep _interval;
};

/*
 * Author: WaldoTheWarfighter
 * Virtual Vehicle Depot helper - applies configured hitpoint damage to a spawned depot vehicle after
 * an optional random delay window. Part of the WIP Virtual Vehicle Depot. Registered as
 * Waldo_fnc_VVDVehicleDamage.
 *
 * Arguments:
 * 0: _veh <OBJECT> - the vehicle to damage
 * 1: _hitpointsDamage <ARRAY<NUMBER>> - damage values by index in the vehicle's
 *    getAllHitPointsDamage names array, not [name, damage] pairs.
 * 2: _damageDelays <ARRAY> - [minDelay, maxDelay] seconds before applying
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * private _damage = (getAllHitPointsDamage _veh) select 2;
 * if (count _damage > 0) then {_damage set [0, 0.5]; [_veh, _damage, [0, 5]] spawn Waldo_fnc_VVDVehicleDamage;};
 * Locality and authority: Runs where the spawned vehicle is local, normally the client's
 * depot-spawn path. A repeat call applies another damage pass after its own delay; current
 * vehicle damage replicates to JIP clients.
 * Current caller: Waldo_fnc_VVDOpen after a vehicle is spawned.
 * Result: The specified hitpoints reach their requested damage after the chosen delay.
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

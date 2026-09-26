/*
 * Author: WaldoTheWarfighter
 * Squad fire control while in contact: close-threat priority, target distribution and disciplined
 * suppression.
 *
 * Close threat: a soldier with an enemy believed within 20 m targets it immediately.
 * Target distribution: when two or more enemies are visible, soldiers whose target already has more
 * than Waldo_AIPass_FireControl_MaxShootersPerTarget shooters switch to an enemy nobody is engaging.
 * A switched soldier keeps his target for 6 s, so orders do not flicker.
 * Suppression: at an enemy that is known but not currently seen (last seen 3-30 s ago), or at the
 * drill's enemy while a flank is running, up to Waldo_AIPass_FireControl_MaxSuppressors soldiers
 * (machine gunners first) fire suppressively. A suppressor needs at least two magazines and 60 rounds
 * for his weapon, must not himself be heavily suppressed, and must have a clear line of fire
 * (Waldo_fnc_AIPassLineOfFireClear keeps friendlies, including the flanking element, and civilians out
 * of the cone). Each suppressor rests 8 s between bursts. Flank element members are left alone.
 * The pass adds no detection: only enemies the engine already knows are used.
 * Locality and authority: call where the group is local; all orders are local-argument commands.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: enemies <ARRAY> - from Waldo_fnc_AIPassKnowledge
 *
 * Return Value:
 * Number - orders issued
 *
 * Example:
 * [_group, _state, _enemies] call Waldo_fnc_AIPassFireControl;
 * Result: fire is spread across visible enemies and a hidden enemy is kept under suppression.
 *
 * Current caller: Waldo_fnc_AIPassGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
if (_enemies isEqualTo []) exitWith {0};
private _now = time;
private _drill = _state getOrDefault ["drill", createHashMap];
private _drillUnits = _drill getOrDefault ["units", []];
private _members = (units _group) select {alive _x && {local _x} && {vehicle _x == _x} && {!(_x in _drillUnits)} && {primaryWeapon _x != ""}};
if (_members isEqualTo []) exitWith {0};
private _orders = 0;
private _held = {(_this getVariable ["Waldo_AIPass_TargetHold", -1]) > _now};

// Close threat first.
{
    private _unit = _x;
    private _closest = objNull;
    private _closestDistance = 20;
    {
        private _distance = _unit distance2D (_x select 1);
        if ((_x select 2) <= 5 && {_distance < _closestDistance}) then {_closest = _x select 0; _closestDistance = _distance};
    } forEach _enemies;
    if (!isNull _closest && {assignedTarget _unit != _closest}) then {
        _unit doTarget _closest;
        _unit doFire _closest;
        _unit setVariable ["Waldo_AIPass_TargetHold", _now + 6];
        _orders = _orders + 1;
    };
} forEach _members;

// Target distribution across visible enemies.
private _visible = (_enemies select {(_x select 2) <= 3}) apply {_x select 0};
if (count _visible >= 2) then {
    private _maximum = (missionNamespace getVariable ["Waldo_AIPass_FireControl_MaxShootersPerTarget", 2]) max 1;
    // Parallel arrays keyed by object: `find` compares objects directly, with no string keys.
    private _targets = [];
    private _counts = [];
    private _addShooter = {
        params ["_target", "_delta"];
        private _index = _targets find _target;
        if (_index < 0) then {_targets pushBack _target; _counts pushBack _delta} else {_counts set [_index, (_counts select _index) + _delta]};
    };
    private _shootersOn = {
        private _index = _targets find _this;
        if (_index < 0) then {0} else {_counts select _index}
    };
    {
        private _target = assignedTarget _x;
        if (!isNull _target) then {[_target, 1] call _addShooter};
    } forEach _members;
    {
        private _unit = _x;
        private _target = assignedTarget _unit;
        if (!isNull _target && {!(_unit call _held)} && {(_target call _shootersOn) > _maximum}
            && {([_unit] call Waldo_fnc_AIPassUnitRole) != "AT"}) then {
            private _freeIndex = _visible findIf {(_x call _shootersOn) == 0};
            if (_freeIndex >= 0) then {
                private _free = _visible select _freeIndex;
                _unit doTarget _free;
                _unit setVariable ["Waldo_AIPass_TargetHold", _now + 6];
                [_target, -1] call _addShooter;
                [_free, 1] call _addShooter;
                _orders = _orders + 1;
            };
        };
    } forEach _members;
};

// Disciplined suppression at a known but unseen enemy, or the enemy a flank is working round.
private _suppressPos = [];
private _hiddenIndex = _enemies findIf {(_x select 2) > 3 && {(_x select 2) <= 30} && {(_x select 3) <= 500}};
if (_hiddenIndex >= 0) then {_suppressPos = (_enemies select _hiddenIndex) select 1};
if (_suppressPos isEqualTo [] && {count _drill > 0}) then {_suppressPos = _drill getOrDefault ["enemyPos", []]};
if (_suppressPos isNotEqualTo []) then {
    private _targetASL = ATLToASL _suppressPos;
    private _limit = missionNamespace getVariable ["Waldo_AIPass_FireControl_MaxSuppressors", 2];
    private _active = {(_x getVariable ["Waldo_AIPass_LastSuppress", -1e6]) > _now - 8} count _members;
    private _ranked = [];
    {_ranked pushBack [[1, 0] select (([_x] call Waldo_fnc_AIPassUnitRole) == "MG"), _forEachIndex]} forEach _members;
    _ranked sort true;
    {
        if (_active >= _limit) exitWith {};
        private _unit = _members select (_x select 1);
        if ((_unit getVariable ["Waldo_AIPass_LastSuppress", -1e6]) <= _now - 8 && {getSuppression _unit < 0.5}) then {
            private _weapon = primaryWeapon _unit;
            private _compatible = compatibleMagazines _weapon;
            private _spare = (magazinesAmmo _unit) select {(_x select 0) in _compatible};
            private _rounds = _unit ammo _weapon;
            {_rounds = _rounds + (_x select 1)} forEach _spare;
            if (count _spare >= 2 && {_rounds >= 60} && {[_unit, _targetASL] call Waldo_fnc_AIPassLineOfFireClear}) then {
                _unit doSuppressiveFire _targetASL;
                _unit setVariable ["Waldo_AIPass_LastSuppress", _now];
                _active = _active + 1;
                _orders = _orders + 1;
            };
        };
    } forEach _ranked;
};
_orders

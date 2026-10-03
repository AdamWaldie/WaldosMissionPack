/*
 * Author: WaldoTheWarfighter
 * Squad fire control while in contact: close-threat priority, target distribution and disciplined
 * suppression.
 *
 * Close threat: a stationary or covering soldier with an enemy believed within 20 m targets it
 * immediately. Actors whose finite tactical movement Cortex currently owns keep TARGET, AUTOTARGET
 * and FIREWEAPON available and may engage naturally, but this function never injects doTarget/doFire
 * into them. Arma translates that pair into an ATTACK pursuit command which replaces their doMove,
 * fragments the fire team and makes movement recovery fight Cortex's own fire-control order.
 * Target distribution: when two or more enemies are visible, soldiers whose target already has more
 * than Waldo_AIPass_FireControl_MaxShootersPerTarget shooters switch to an enemy nobody is engaging.
 * A switched soldier keeps his target for 6 s, so orders do not flicker.
 * Suppression: at an enemy that is known but not currently seen (last seen 3-30 s ago), or at the
 * drill's enemy while a flank is running, up to Waldo_AIPass_FireControl_MaxSuppressors soldiers
 * (machine gunners first) fire suppressively. One eligible suppressor is ordered at a time; the group
 * rotates through its candidates at a 2.5-4 s interval. The first order receives a 0.25-2.25 s
 * short per-group random delay, so separate squads do not produce an uncanny global volley. This models
 * alternating or "talking" fire inside an element while leaving unrelated elements asynchronous.
 * A suppressor needs at least two magazines and 60 rounds
 * for his weapon, must not himself be heavily suppressed, and must have a clear line of fire
 * (Waldo_fnc_CortexLineOfFireClear keeps friendlies, including the flanking element, and civilians out
 * of the cone). Each suppressor rests 8 s between bursts. Flank element members are left alone.
 * The pass adds no detection. A live coordinated role may suppress its reported position
 * without assigning an unseen object target; all normal fire safety and ammo limits apply.
 * Locality and authority: call where the group is local; all orders are local-argument commands.
 * An opportunistic drill grenade thrower is not retargeted during its two-second action window;
 * the grenade never blocks the squad manoeuvre state.
 * Repeat/JIP: checks current ownership, eligibility and gates on every call. START/MOVE
 * actors are left to normal target acquisition; explicit priority, distribution and suppression
 * remain with stationary elements. Recovering stragglers are excluded. This function creates no JIP actions.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: enemies <ARRAY> - from Waldo_fnc_CortexKnowledge
 *
 * Return Value:
 * Number - orders issued
 *
 * Example:
 * [_group, _state, _enemies] call Waldo_fnc_CortexFireControl;
 * Result: fire is spread across visible enemies and a hidden enemy is kept under suppression.
 *
 * Current caller: Waldo_fnc_CortexGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
if (isNull _group || {!local _group} || {!([_group] call Waldo_fnc_CortexIsEligible)}
    || {!([_group,"Waldo_AIPass_FireControl_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}
    ) exitWith {0};
private _reported = [];
private _role = _group getVariable ["Waldo_Cortex_SupportRole",[]];
private _lease = _group getVariable ["Waldo_AIPass_SupportLease",[]];
if (count _role == 5 && {count _lease == 6}
    && {(_role select 0) == (_lease select 0)}
    && {(_role select 0) == (_state getOrDefault ["supportToken",""])}
    && {serverTime < (_lease select 2)} && {_state getOrDefault ["assaulting",false]}
    && {[_group,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled}) then {
    _reported = +(_role select 4);
};
if (_enemies isEqualTo [] && {_reported isEqualTo []}) exitWith {
    // A later contact receives a fresh phase rather than inheriting an overdue
    // window which would make every group fire together on reacquisition.
    _group setVariable ["Waldo_AIPass_NextSuppress",nil];
    0
};
if (!(combatMode _group in ["YELLOW","RED"])) exitWith {0};
private _now = time;
private _drill = _state getOrDefault ["drill", createHashMap];
// The stationary element must keep supporting a successive advance.
private _drillUnits = if ((_drill getOrDefault ["teams",[]]) isEqualTo []) then {
    _drill getOrDefault ["units",[]]
} else {
    if ((_drill getOrDefault ["stage",""]) in ["START","MOVE"]) then {_drill getOrDefault ["movers",_drill getOrDefault ["units",[]]]} else {[]}
};
// Rejoining actors still own movement, even while the main element pauses.
// An opportunistic grenade reserves only its thrower for the short next-frame
// action window; it never blocks the squad's manoeuvre state.
if (_now < (_drill getOrDefault ["grenadeActionUntil",-1])) then {
    _drillUnits = +_drillUnits;
    _drillUnits pushBackUnique (_drill getOrDefault ["grenadeThrower",objNull]);
};
private _recovering = (_drill getOrDefault ["recovery",[]]) apply {_x select 0};
private _eligible = (units _group) select {([_x] call Waldo_fnc_CortexCombatEffective) && {local _x} && {unitCombatMode _x in ["YELLOW","RED"]} && {vehicle _x == _x} && {!(_x in _recovering)} && {primaryWeapon _x != ""}};
private _members = _eligible - _drillUnits;
private _movingMembers = _eligible arrayIntersect _drillUnits;
if (_members isEqualTo [] && {_movingMembers isEqualTo []}) exitWith {0};
private _orders = 0;
private _held = {(_this getVariable ["Waldo_AIPass_TargetHold", -1]) > _now};

// Close threat first for stationary and covering members. Moving actors retain normal
// TARGET/AUTOTARGET/FIREWEAPON behavior, but an explicit doTarget/doFire pair would
// replace their owned LEADER PLANNED destination with native ATTACK pursuit.
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
            && {([_unit] call Waldo_fnc_CortexUnitRole) != "AT"}) then {
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
private _suppressPos = +_reported;
private _hiddenIndex = _enemies findIf {(_x select 2) > 3 && {(_x select 2) <= 30} && {(_x select 3) <= 500}};
if (_hiddenIndex >= 0) then {_suppressPos = (_enemies select _hiddenIndex) select 1};
if (_suppressPos isEqualTo [] && {count _drill > 0}) then {_suppressPos = _drill getOrDefault ["enemyPos", []]};
if (_suppressPos isNotEqualTo []) then {
    private _targetASL = ATLToASL _suppressPos;
    private _limit = missionNamespace getVariable ["Waldo_AIPass_FireControl_MaxSuppressors", 2];
    private _active = {(_x getVariable ["Waldo_AIPass_LastSuppress", -1e6]) > _now - 8} count _members;
    private _nextWindow = _group getVariable ["Waldo_AIPass_NextSuppress",-1];
    if (_nextWindow < 0) then {
        _nextWindow = _now + 0.25 + random 2;
        _group setVariable ["Waldo_AIPass_NextSuppress",_nextWindow];
    };
    if (_now >= _nextWindow && {_active < _limit}) then {
        private _ranked = [];
        {_ranked pushBack [[1, 0] select (([_x] call Waldo_fnc_CortexUnitRole) == "MG"), _forEachIndex]} forEach _members;
        _ranked sort true;
        private _cursor = (_group getVariable ["Waldo_AIPass_SuppressCursor",0]) mod (count _ranked max 1);
        private _ordered = (_ranked select [_cursor]) + (_ranked select [0,_cursor]);
        private _issued = false;
        {
            if (_issued) exitWith {};
            private _unit = _members select (_x select 1);
            if ((_unit getVariable ["Waldo_AIPass_LastSuppress", -1e6]) <= _now - 8 && {getSuppression _unit < 0.5}) then {
                private _weapon = primaryWeapon _unit;
                private _compatible = compatibleMagazines _weapon;
                private _spare = (magazinesAmmo _unit) select {(_x select 0) in _compatible};
                private _rounds = _unit ammo _weapon;
                {_rounds = _rounds + (_x select 1)} forEach _spare;
                if (count _spare >= 2 && {_rounds >= 60} && {[_unit, _targetASL] call Waldo_fnc_CortexLineOfFireClear}) then {
                    _unit doSuppressiveFire _targetASL;
                    _unit setVariable ["Waldo_AIPass_LastSuppress", _now];
                    _group setVariable ["Waldo_AIPass_SuppressCursor",(_cursor + 1) mod count _ranked];
                    _group setVariable ["Waldo_AIPass_NextSuppress",_now + 2.5 + random 1.5];
                    _issued = true;
                    _orders = _orders + 1;
                };
            };
        } forEach _ordered;
        if (!_issued) then {_group setVariable ["Waldo_AIPass_NextSuppress",_now + 1]};
    };
} else {
    _group setVariable ["Waldo_AIPass_NextSuppress",nil];
};
_orders

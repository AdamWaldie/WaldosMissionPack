/*
 * Author: WaldoTheWarfighter
 * Chooses each soldier's stance from the height of the cover in front of him.
 *
 * For stationary soldiers on foot in contact (including drill covering elements, not garrisoned), three short rays are cast 3 m
 * towards the enemy at 1.5 m, 1.0 m and 0.5 m. Low protection with kneeling clearance selects MIDDLE;
 * protection at lower heights with standing clearance selects UP. Fully blocked cover retains AUTO.
 * These local height probes are approximate clearance checks, not proof of a clear shot to a target.
 * With no cover in front, the stance is handed back to the engine (AUTO). Each soldier is re-checked
 * at most every 10 s. A soldier briefly reserved for an opportunistic grenade keeps his stance
 * during that action; the grenade never blocks the manoeuvre state. A rotating cursor limits each group step to two sampled soldiers (six rays),
 * avoiding a whole-squad ray burst; ineligible soldiers do not consume the sampling allowance. Only soldiers whose stance was AUTO, or was set by
 * the pass, are changed, so mission-maker stances are respected. The pass returns every stance it set
 * to AUTO when the squad goes back to CALM only while it still matches the applied stance.
 * Repeat/JIP: the public applied-stance record survives ownership transfer; later different stances
 * relinquish Cortex ownership and are preserved during cleanup.
 * Locality and authority: call where the group is local.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: enemies <ARRAY> - from Waldo_fnc_CortexKnowledge
 *
 * Return Value:
 * Number - stances changed
 *
 * Example:
 * [_group, _state, _enemies] call Waldo_fnc_CortexStance;
 * Result: a soldier behind a low wall kneels to fire over it instead of standing exposed.
 *
 * Current caller: Waldo_fnc_CortexGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
private _enemyPos = _state getOrDefault ["enemyPos", []];
if (count _enemyPos < 2) exitWith {0};
private _now = time;
private _drill = _state getOrDefault ["drill", createHashMap];
private _drillUnits = if ((_drill getOrDefault ["stage",""]) in ["START","MOVE"]) then {
    +(_drill getOrDefault ["movers",_drill getOrDefault ["units",[]]])
} else {[]};
{_drillUnits pushBackUnique (_x select 0)} forEach (_drill getOrDefault ["recovery",[]]);
if (_now < (_drill getOrDefault ["grenadeActionUntil",-1])) then {
    _drillUnits pushBackUnique (_drill getOrDefault ["grenadeThrower",objNull]);
};
private _changed = 0;
private _members=units _group;
private _count=count _members;
if (_count == 0) exitWith {0};
private _cursor=(_state getOrDefault ["stanceCursor",0]) mod _count;
private _sampled=0;
for "_offset" from 0 to (_count-1) do {
    if (_sampled >= 2) exitWith {};
    private _index=(_cursor+_offset) mod _count;
    private _unit=_members select _index;
    _state set ["stanceCursor",(_index+1) mod _count];
    private _currentStance=toUpperANSI (unitPos _unit);
    if (local _unit && {_unit getVariable ["Waldo_AIPass_StanceSet",false]}
        && {_currentStance != (_unit getVariable ["Waldo_Cortex_AppliedStance",""])}) then {
        _unit setVariable ["Waldo_AIPass_StanceSet",nil,true];
        _unit setVariable ["Waldo_Cortex_AppliedStance",nil,true];
    };
    if (alive _unit && {local _unit} && {vehicle _unit == _unit} && {abs speed _unit < 1} && {!(_unit in _drillUnits)}
        && {(_unit getVariable ["Waldo_AIPass_GarrisonPos", []]) isEqualTo []}
        && {_now >= (_unit getVariable ["Waldo_AIPass_StanceAt", -1])}
        && {_currentStance == "AUTO" || {_unit getVariable ["Waldo_AIPass_StanceSet", false]}}) then {
        _sampled=_sampled+1;
        _unit setVariable ["Waldo_AIPass_StanceAt", _now + 10];
        private _base = getPosASL _unit;
        private _direction = (getPosATL _unit) vectorFromTo _enemyPos;
        _direction set [2, 0];
        _direction = (vectorNormalized _direction) vectorMultiply 3;
        private _blocked = {
            params ["_height"];
            private _from = _base vectorAdd [0, 0, _height];
            (lineIntersectsSurfaces [_from, _from vectorAdd _direction, _unit, objNull, true, 1, "FIRE", "GEOM"]) isNotEqualTo []
        };
        // A blocked ray describes protection, not a usable weapon height.
        // Select clearance above that protection; fully obstructed positions remain
        // engine-controlled rather than pinning the soldier behind a solid wall.
        private _lowBlocked=[0.5] call _blocked;
        private _middleBlocked=[1.0] call _blocked;
        private _highBlocked=[1.5] call _blocked;
        private _stance = switch (true) do {
            case (_lowBlocked && {!_middleBlocked}): {"MIDDLE"};
            case ((_lowBlocked || {_middleBlocked}) && {!_highBlocked}): {"UP"};
            default {"AUTO"};
        };
        if (toUpperANSI (unitPos _unit) != _stance) then {
            _unit setUnitPos _stance;
            _unit setVariable ["Waldo_Cortex_AppliedStance",_stance,true];
            _unit setVariable ["Waldo_AIPass_StanceSet", _stance != "AUTO", true];
            _changed = _changed + 1;
        };
    };
};
_changed

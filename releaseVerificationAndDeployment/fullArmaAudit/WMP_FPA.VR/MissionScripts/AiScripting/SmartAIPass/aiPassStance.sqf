/*
 * Author: WaldoTheWarfighter
 * Chooses each soldier's stance from the height of the cover in front of him, as Digii did.
 *
 * For soldiers on foot in contact (not in a drill and not garrisoned), three short rays are cast 3 m
 * towards the enemy at 1.5 m, 1.0 m and 0.5 m. Cover that blocks at chest height when standing means
 * UP (fire over a wall), cover that blocks at kneeling height means MIDDLE, and low cover means DOWN.
 * With no cover in front, the stance is handed back to the engine (AUTO). Each soldier is re-checked
 * at most every 10 s, so there is no stance flicker. Only soldiers whose stance was AUTO, or was set by
 * the pass, are changed, so mission-maker stances are respected. The pass returns every stance it set
 * to AUTO when the squad goes back to CALM.
 * Locality and authority: call where the group is local.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: enemies <ARRAY> - from Waldo_fnc_AIPassKnowledge
 *
 * Return Value:
 * Number - stances changed
 *
 * Example:
 * [_group, _state, _enemies] call Waldo_fnc_AIPassStance;
 * Result: a soldier behind a low wall kneels to fire over it instead of standing exposed.
 *
 * Current caller: Waldo_fnc_AIPassGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
private _enemyPos = _state getOrDefault ["enemyPos", []];
if (count _enemyPos < 2) exitWith {0};
private _now = time;
private _drillUnits = (_state getOrDefault ["drill", createHashMap]) getOrDefault ["units", []];
private _changed = 0;
{
    private _unit = _x;
    if (alive _unit && {local _unit} && {vehicle _unit == _unit} && {!(_unit in _drillUnits)}
        && {(_unit getVariable ["Waldo_AIPass_GarrisonPos", []]) isEqualTo []}
        && {_now >= (_unit getVariable ["Waldo_AIPass_StanceAt", -1])}
        && {(unitPos _unit) == "Auto" || {_unit getVariable ["Waldo_AIPass_StanceSet", false]}}) then {
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
        private _stance = switch (true) do {
            case ([1.5] call _blocked): {"UP"};
            case ([1.0] call _blocked): {"MIDDLE"};
            case ([0.5] call _blocked): {"DOWN"};
            default {"AUTO"};
        };
        if (toUpperANSI (unitPos _unit) != _stance) then {
            _unit setUnitPos _stance;
            _unit setVariable ["Waldo_AIPass_StanceSet", _stance != "AUTO", true];
            _changed = _changed + 1;
        };
    };
} forEach units _group;
_changed

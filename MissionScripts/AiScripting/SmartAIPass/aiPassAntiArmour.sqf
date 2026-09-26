/*
 * Author: WaldoTheWarfighter
 * Puts the squad's best anti-tank gunner onto a known armoured vehicle, clear of backblast.
 *
 * From Smart Combat V2: when a tank or armoured vehicle the squad knows about is within 600 m, the
 * launcher gunner with ammunition, least damage and least suppression is ordered to target and fire on
 * it, unless he is already engaging it. Before firing, the backblast area (4 m behind him) is
 * checked for walls and for friendly soldiers; if it is blocked he first moves to a covered spot
 * nearby. An order is held for 15 s. A squad with no anti-tank capability facing armour is handled by
 * morale (Waldo_fnc_AIPassMorale), which can make it withdraw.
 * Locality and authority: call where the group is local.
 *
 * Review contract: A blocked backblast causes only a relocation request. A later group step must recheck clearance before ordering the shot.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: enemies <ARRAY> - from Waldo_fnc_AIPassKnowledge
 *
 * Return Value:
 * Boolean - true when an anti-tank order was given
 *
 * Example:
 * [_group, _state, _enemies] call Waldo_fnc_AIPassAntiArmour;
 * Result: the rifleman with the launcher engages the APC instead of the whole squad firing rifles at it.
 *
 * Current caller: Waldo_fnc_AIPassGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
private _armourIndex = _enemies findIf {
    private _enemy = vehicle (_x select 0);
    (_enemy isKindOf "Tank" || {_enemy isKindOf "Wheeled_APC_F"}) && {(_x select 3) <= 600} && {(_x select 2) <= 30}
};
if (_armourIndex < 0) exitWith {false};
(_enemies select _armourIndex) params ["_enemyUnit", "_enemyPos"];
private _armour = vehicle _enemyUnit;
private _now = time;
private _gunners = (units _group) select {
    alive _x && {local _x} && {vehicle _x == _x} && {([_x] call Waldo_fnc_AIPassUnitRole) == "AT"}
};
if (_gunners findIf {assignedTarget _x == _armour && {(_x getVariable ["Waldo_AIPass_TargetHold", -1]) > _now}} >= 0) exitWith {false};
private _ranked = [];
{_ranked pushBack [damage _x + getSuppression _x, _forEachIndex]} forEach _gunners;
_ranked sort true;
if (_ranked isEqualTo []) exitWith {false};
private _gunner = _gunners select ((_ranked select 0) select 1);

private _eye = eyePos _gunner;
private _behind = _eye vectorAdd ((_eye vectorFromTo (ATLToASL _enemyPos)) vectorMultiply -4);
private _blocked = (lineIntersectsSurfaces [_eye, _behind, _gunner, objNull, true, 1]) isNotEqualTo []
    || {((_gunner nearEntities ["CAManBase", 6]) select {_x != _gunner && {side group _x == side _group}}) findIf {
        private _offset = (getPosASL _x) vectorDiff (getPosASL _gunner);
        (_offset vectorDotProduct ((ATLToASL _enemyPos) vectorDiff (getPosASL _gunner))) < 0
    } >= 0};
if (_blocked) exitWith {
    private _spot = ([(getPosATL _gunner) getPos [6, (_enemyPos getDir _gunner) + selectRandom [-70, 70]], _enemyPos, 8] call Waldo_fnc_AIPassFindCover) select 0;
    _gunner doMove _spot;
    false
};
_gunner doTarget _armour;
_gunner doFire _armour;
_gunner setVariable ["Waldo_AIPass_TargetHold", _now + 15];
true

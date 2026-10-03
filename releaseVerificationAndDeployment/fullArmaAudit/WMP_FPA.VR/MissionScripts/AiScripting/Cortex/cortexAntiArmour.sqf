/*
 * Author: WaldoTheWarfighter
 * Puts the squad's best anti-tank gunner onto a known armoured vehicle, clear of backblast.
 *
 * When a tank or armoured vehicle the squad knows about is within 600 m, the
 * launcher gunner with ammunition, least damage and least suppression is ordered to target and fire on
 * it, unless he is already engaging it. Before firing, the backblast area (4 m behind him) is
 * checked for walls and for friendly soldiers; if it is blocked he first moves to a covered spot
 * nearby under one ten-second actor reservation. A replacement destination cancels that relocation;
 * it is never reissued every tick. An engagement order is held for 15 s. A squad with no anti-tank capability facing armour is handled by
 * morale (Waldo_fnc_CortexMorale), which can make it withdraw.
 * Locality and authority: call where the group is local.
 *
 * Review contract: A blocked backblast causes only a relocation request. A later group step must recheck clearance before ordering the shot.
 * Active actor reservations and every member of a tactical drill are not relocated. Explicit
 * holding/clearing orders and disabled PATH/MOVE also prevent relocation; stationary support
 * actors may still engage if their existing position has safe backblast.
 *
 * An opportunistic drill grenade thrower is not retargeted during its two-second action window;
 * the grenade never blocks the squad manoeuvre state.
 * Repeat/JIP: current feature gates and eligibility are rechecked; owner jobs are retired on migration.
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: enemies <ARRAY> - from Waldo_fnc_CortexKnowledge
 *
 * Return Value:
 * Boolean - true when an anti-tank order was given
 *
 * Example:
 * [_group, _state, _enemies] call Waldo_fnc_CortexAntiArmour;
 * Result: the rifleman with the launcher engages the APC instead of the whole squad firing rifles at it.
 *
 * Current caller: Waldo_fnc_CortexGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
if (isNull _group || {!local _group} || {!([_group] call Waldo_fnc_CortexIsEligible)}
    || {!([_group,"Waldo_AIPass_AntiArmour_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}
    || {!(combatMode _group in ["YELLOW","RED"])}) exitWith {false};
private _now = time;
private _relocation = _state getOrDefault ["antiArmourRelocation",[]];
private _relocationBlocks = false;
if (count _relocation == 3) then {
    _relocation params ["_relocating","_relocationSpot","_relocationUntil"];
    private _stillOurs = alive _relocating && {local _relocating} && {group _relocating == _group}
        && {((expectedDestination _relocating) select 0) distance2D _relocationSpot < 1};
    if (_stillOurs && {_relocating distance2D _relocationSpot > 2} && {_now < _relocationUntil}) then {
        _relocationBlocks = true;
    } else {
        _relocating setVariable ["Waldo_Cortex_ActorMove",nil];
        _state deleteAt "antiArmourRelocation";
        if (_now >= _relocationUntil || {!_stillOurs}) then {[_state,"antiArmourMove",10] call Waldo_fnc_CortexCooldown};
    };
};
if (_relocationBlocks || {[_state,"antiArmourMove"] call Waldo_fnc_CortexCooldown}) exitWith {false};
private _drill = _state getOrDefault ["drill",createHashMap];
private _moving = if ((_drill getOrDefault ["stage",""]) in ["START","MOVE"]) then {
    _drill getOrDefault ["movers",_drill getOrDefault ["units",[]]]
} else {[]};
// Reserve an opportunistic grenade thrower only for its short action window.
if (time < (_drill getOrDefault ["grenadeActionUntil",-1])) then {
    _moving = +_moving;
    _moving pushBackUnique (_drill getOrDefault ["grenadeThrower",objNull]);
};
private _recovering = (_drill getOrDefault ["recovery",[]]) apply {_x select 0};
private _armourIndex = _enemies findIf {
    private _enemy = vehicle (_x select 0);
    (_enemy isKindOf "Tank" || {_enemy isKindOf "Wheeled_APC_F"}) && {(_x select 3) <= 600} && {(_x select 2) <= 30}
};
if (_armourIndex < 0) exitWith {false};
(_enemies select _armourIndex) params ["_enemyUnit", "_enemyPos"];
private _armour = vehicle _enemyUnit;
private _gunners = (units _group) select {
    private _actorMove = _x getVariable ["Waldo_Cortex_ActorMove",[]];
    ([_x] call Waldo_fnc_CortexCombatEffective) && {local _x} && {!(_x in _moving)} && {!(_x in _recovering)} && {unitCombatMode _x in ["YELLOW","RED"]} && {vehicle _x == _x} && {"AT" in ([_x] call Waldo_fnc_CortexCapabilities)}
        && {count _actorMove != 3 || {_now >= (_actorMove select 2)}}
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
// Holding/clearing owns the destination even when the gunner may fire from it.
if (_blocked && {!(_gunner checkAIFeature "PATH") || {!(_gunner checkAIFeature "MOVE")}
    || {_gunner in (_drill getOrDefault ["units",[]])}
    || {(_group getVariable ["Waldo_AIPass_Garrison",[]]) isNotEqualTo []}
    || {(_group getVariable ["Waldo_AIPass_Defend",[]]) isNotEqualTo []}
    || {_group getVariable ["Waldo_AIPass_ClearBuilding",false]}}) exitWith {false};
if (_blocked) exitWith {
    private _spot = ([(getPosATL _gunner) getPos [6, (_enemyPos getDir _gunner) + selectRandom [-70, 70]], _enemyPos, 8, [], _group] call Waldo_fnc_CortexFindCover) select 0;
    _gunner doMove _spot;
    _gunner setVariable ["Waldo_Cortex_ActorMove",["ANTI_ARMOUR",+_spot,_now+10]];
    _state set ["antiArmourRelocation",[_gunner,+_spot,_now+10]];
    false
};
_gunner doTarget _armour;
_gunner doFire _armour;
_gunner setVariable ["Waldo_AIPass_TargetHold", _now + 15];
true

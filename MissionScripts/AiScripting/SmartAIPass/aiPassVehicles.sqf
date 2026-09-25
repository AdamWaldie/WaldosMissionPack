/*
 * Author: WaldoTheWarfighter
 * Vehicle drills for a squad in contact, from Digii AI: dismount infantry under fire, and pull a
 * damaged vehicle back behind smoke.
 *
 * Dismount: infantry riding as cargo in the squad's own ground vehicle get out once an enemy is
 * believed within 400 m, instead of dying inside a truck. They are recorded and ordered back in when
 * the squad returns to CALM (Waldo_fnc_AIPassRestoreCalm).
 * Withdraw: a vehicle that can still move but is at 50% damage or has lost its weapons, with an enemy
 * within 800 m, fires its smoke launcher (Waldo_fnc_AIPassFireCountermeasure). If the whole squad is
 * mounted, it withdraws 300 m away from the enemy (RETREAT phase, through an inserted waypoint). Each
 * vehicle withdraws once per engagement.
 * Vehicles owned by other WMP features never reach this function (Waldo_fnc_AIPassIsEligible).
 * Locality and authority: call where the group is local.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: enemies <ARRAY> - from Waldo_fnc_AIPassKnowledge
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_group, _state, _enemies] call Waldo_fnc_AIPassVehicles;
 * Result: a squad caught in its truck bails out and fights on foot.
 *
 * Current caller: Waldo_fnc_AIPassGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
if (_enemies isEqualTo []) exitWith {};
private _vehicles = [];
{
    private _vehicle = vehicle _x;
    if (_vehicle != _x && {alive _x} && {!(_vehicle in _vehicles)} && {effectiveCommander _vehicle in units _group}) then {_vehicles pushBack _vehicle};
} forEach units _group;
if (_vehicles isEqualTo []) exitWith {};
private _enemyPos = (_enemies select 0) select 1;
private _withdrawn = _state getOrDefault ["withdrawn", []];
{
    private _vehicle = _x;
    private _distance = _vehicle distance2D _enemyPos;
    if (_vehicle isKindOf "LandVehicle" && {!(_vehicle isKindOf "StaticWeapon")} && {_distance < 400}) then {
        private _cargo = (crew _vehicle) select {
            alive _x && {local _x} && {group _x == _group} && {toLowerANSI ((assignedVehicleRole _x) param [0, ""]) == "cargo"}
        };
        if (_cargo isNotEqualTo []) then {
            private _dismounted = _state getOrDefault ["dismounted", []];
            {
                unassignVehicle _x;
                doGetOut _x;
                _dismounted pushBack [_x, _vehicle];
            } forEach _cargo;
            _state set ["dismounted", _dismounted];
        };
    };
    if (alive _vehicle && {canMove _vehicle} && {!(_vehicle in _withdrawn)} && {_distance < 800}
        && {damage _vehicle >= 0.5 || {!canFire _vehicle && {count (weapons _vehicle + (_vehicle weaponsTurret [0])) > 0}}}) then {
        _withdrawn pushBack _vehicle;
        _state set ["withdrawn", _withdrawn];
        [_vehicle] call Waldo_fnc_AIPassFireCountermeasure;
        if ((units _group) findIf {alive _x && {vehicle _x == _x}} < 0) then {
            private _away = (getPosATL _vehicle) getPos [300, _enemyPos getDir _vehicle];
            if (!surfaceIsWater _away) then {
                [_group, _away, 40] call Waldo_fnc_AIPassGroupMove;
                _state set ["phase", "RETREAT"];
                _state set ["phaseStart", time];
            };
        };
    };
} forEach _vehicles;

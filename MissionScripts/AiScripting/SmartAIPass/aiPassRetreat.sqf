/*
 * Author: WaldoTheWarfighter
 * Pulls a broken squad back, away from the enemy, under smoke.
 *
 * The retreat point is Waldo_AIPass_Morale_RetreatDistance (scaled by the behaviour profile's
 * retreatScale) from the leader, directly away from the last known enemy position, turning up to 60
 * degrees either way to avoid water. The squad moves through an inserted waypoint
 * (Waldo_fnc_AIPassGroupMove) at FULL speed, so its own waypoints resume afterwards. Soldiers holding
 * ground from a drill fall back with it. One soldier throws smoke towards the enemy, and with
 * artillery support and Waldo_AIPass_ArtillerySmoke_Enable on, a friendly battery on the same machine
 * lays a smoke screen between the squad and the enemy, never within 50 m of friendlies. Any flank drill ends because the phase
 * leaves CONTACT. The speed change is recorded and restored when the squad returns to CALM.
 * Locality and authority: call where the group is local.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 *
 * Return Value:
 * Boolean - true when the squad started retreating
 *
 * Example:
 * [_group, _state] call Waldo_fnc_AIPassRetreat;
 * Result: the survivors fall back 200 m and regroup.
 *
 * Current caller: Waldo_fnc_AIPassGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]]];
private _leader = leader _group;
private _enemyPos = _state getOrDefault ["enemyPos", []];
if (count _enemyPos < 2) exitWith {false};
private _distance = (missionNamespace getVariable ["Waldo_AIPass_Morale_RetreatDistance", 200]) * ([_group, "retreatScale"] call Waldo_fnc_AIPassProfile);
private _away = _enemyPos getDir _leader;
private _point = [];
{
    private _candidate = (getPosATL _leader) getPos [_distance, _away + _x];
    if (!surfaceIsWater _candidate) exitWith {_point = _candidate};
} forEach [0, 30, -30, 60, -60];
if (_point isEqualTo []) exitWith {false};
[_group, _point, 30] call Waldo_fnc_AIPassGroupMove;
if (speedMode _group != "FULL") then {
    if !(_state getOrDefault ["speedChanged", false]) then {_state set ["baseSpeed", speedMode _group]};
    _state set ["speedChanged", true];
    _group setSpeedMode "FULL";
};
{if (alive _x && {local _x}) then {_x doFollow _leader}} forEach (_state getOrDefault ["holders", []]);
_state set ["holders", []];
private _smokers = (units _group) select {alive _x && {local _x} && {vehicle _x == _x}};
if (_smokers isNotEqualTo []) then {[selectRandom _smokers, _enemyPos, "SMOKE"] call Waldo_fnc_AIPassThrowGrenade};
// A retreating squad with a radio asks friendly artillery for a smoke screen between it and the enemy.
if ((missionNamespace getVariable ["Waldo_AIPass_Artillery_Enable", false]) && {[_group,"Waldo_AIPass_ArtillerySmoke_Enable", true] call Waldo_fnc_AIPassFeatureEnabled}
    && {[_leader] call Waldo_fnc_AIPassCanTransmit}) then {
    private _screen = _enemyPos getPos [((_enemyPos distance2D _leader) * 0.4) min 80, _enemyPos getDir _leader];
    private _side = side _group;
    private _friendlyNear = (_screen nearEntities [["CAManBase", "LandVehicle"], 50]) findIf {
        private _otherSide = side group _x;
        alive _x && {_otherSide == civilian || {_side getFriend _otherSide >= 0.6}}
    } >= 0;
    if (!_friendlyNear) then {
        {
            if ([_x, _screen, 0, "SMOKE"] call Waldo_fnc_AIPassArtilleryFire) exitWith {};
        } forEach ((missionNamespace getVariable ["Waldo_AIPass_LocalArtillery", []]) select {
            alive _x && {local _x} && {alive gunner _x} && {side group gunner _x == _side}
            && {(_x getVariable ["Waldo_AIPass_BusyUntil", -1]) < time} && {!([group gunner _x] call Waldo_fnc_AIPassZeusHeld)}
            && {[_x, "SUPPORT"] call Waldo_fnc_AIPassArtilleryRole}
        });
    };
};
_state set ["phase", "RETREAT"];
_state set ["phaseStart", time];
missionNamespace setVariable ["Waldo_AIPass_Retreats", (missionNamespace getVariable ["Waldo_AIPass_Retreats", 0]) + 1];
if (missionNamespace getVariable ["Waldo_AIPass_Debug", false]) then {diag_log format ["[WMP AI PASS] %1 RETREAT to %2", _group, _point]};
true

/*
 * Author: WaldoTheWarfighter
 * Lets a squad in contact call a fire mission from friendly artillery owned by the same machine.
 *
 * Digii's fire support with the audit's fixes: only known enemy positions are used (never omniscient
 * targeting). The target must have been seen in the last 30 s, be at least
 * Waldo_AIPass_Artillery_MinFriendlyDistance from the calling squad, and have an engine position error
 * no larger than Waldo_AIPass_Artillery_MaxError. The caller needs a working, unjammed radio
 * (Waldo_fnc_AIPassCanTransmit). The mission is refused if any friendly or civilian soldier or
 * vehicle is within the minimum distance of the impact point. The first idle same-side battery in
 * range whose role allows support (Waldo_fnc_AIPassArtilleryRole: SUPPORT or BOTH) fires
 * (Waldo_fnc_AIPassArtilleryFire). Counter-battery has its own switch and settings. A squad may call once per
 * Waldo_AIPass_Artillery_Cooldown seconds. Batteries owned by another machine are not used.
 * Locality and authority: call where the requesting group is local.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: enemies <ARRAY> - from Waldo_fnc_AIPassKnowledge
 *
 * Return Value:
 * Boolean - true when a mission was fired
 *
 * Example:
 * [_group, _state, _enemies] call Waldo_fnc_AIPassArtilleryRequest;
 * Result: the enemy mortar team's position is shelled once the squad has a good fix on it.
 *
 * Current caller: Waldo_fnc_AIPassGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
if ([_state, "artillery"] call Waldo_fnc_AIPassCooldown) exitWith {false};
private _batteries = (missionNamespace getVariable ["Waldo_AIPass_LocalArtillery", []]) select {
    alive _x && {local _x} && {alive gunner _x} && {!([group gunner _x] call Waldo_fnc_AIPassZeusHeld)} && {side group gunner _x == side _group}
    && {(_x getVariable ["Waldo_AIPass_BusyUntil", -1]) < time} && {[_x, "SUPPORT"] call Waldo_fnc_AIPassArtilleryRole}
};
if (_batteries isEqualTo []) exitWith {false};
private _minimum = missionNamespace getVariable ["Waldo_AIPass_Artillery_MinFriendlyDistance", 200];
private _maxError = missionNamespace getVariable ["Waldo_AIPass_Artillery_MaxError", 50];
private _targetIndex = _enemies findIf {(_x select 2) <= 30 && {(_x select 3) >= _minimum} && {(_x select 4) <= _maxError}};
if (_targetIndex < 0) exitWith {false};
if !([leader _group] call Waldo_fnc_AIPassCanTransmit) exitWith {[_state, "artillery", 20] call Waldo_fnc_AIPassCooldown; false};
(_enemies select _targetIndex) params ["", "_target", "", "", "_error"];
private _side = side _group;
private _friendlyNear = (_target nearEntities [["CAManBase", "LandVehicle"], _minimum]) findIf {
    private _otherSide = side group _x;
    alive _x && {_otherSide == civilian || {_side getFriend _otherSide >= 0.6}}
} >= 0;
if (_friendlyNear) exitWith {[_state, "artillery", 20] call Waldo_fnc_AIPassCooldown; false};
private _fired = false;
{
    if ([_x, _target, _error] call Waldo_fnc_AIPassArtilleryFire) exitWith {_fired = true};
} forEach _batteries;
[_state, "artillery", [20, missionNamespace getVariable ["Waldo_AIPass_Artillery_Cooldown", 120]] select _fired] call Waldo_fnc_AIPassCooldown;
_fired

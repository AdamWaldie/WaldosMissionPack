/*
 * Author: WaldoTheWarfighter
 * Registers an object as a counter-battery radar for one side (used by counter-battery "RADAR" mode).
 *
 * Any object works, typically a radar prop. While it is alive, enemy artillery firing within
 * Waldo_AIPass_CounterBattery_RadarRange of it is located for that side's batteries. Safe in an Eden
 * init field with no isServer wrapper: copies on other machines do nothing, and the server's own copy
 * registers the radar and publishes the list.
 * Locality and authority: server-authoritative list, broadcast once per registration.
 *
 * Arguments:
 * 0: object <OBJECT>
 * 1: side <SIDE or STRING> - side the radar serves (optional, default: the object's side)
 *
 * Return Value:
 * Boolean - true when registered on the server
 *
 * Example:
 * [this, west] call Waldo_fnc_AIPassRegisterRadar;
 * Result: BLUFOR batteries answer enemy artillery fire detected by this radar.
 *
 * Current callers: mission Eden init fields and scripts.
 */

params [["_object", objNull, [objNull]], ["_side", sideUnknown, [sideUnknown, ""]]];
if (isNull _object) exitWith {false};
if (!isServer) exitWith {false};
if (_side isEqualType sideUnknown) then {
    if (_side == sideUnknown) then {_side = side _object};
    _side = switch (_side) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
};
_side = toUpperANSI _side;
private _radars = (missionNamespace getVariable ["Waldo_AIPass_CounterBatteryRadars", []]) select {alive (_x select 0) && {(_x select 0) != _object}};
_radars pushBack [_object, _side];
missionNamespace setVariable ["Waldo_AIPass_CounterBatteryRadars", _radars, true];
true

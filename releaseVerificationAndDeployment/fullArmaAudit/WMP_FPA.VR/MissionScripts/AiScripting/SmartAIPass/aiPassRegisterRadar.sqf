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
 * 2: enabled <BOOL> - register/update true, remove false (optional, default true)
 *
 * Return Value:
 * Boolean - true when registered on the server
 *
 * Example:
 * [this, west] call Waldo_fnc_AIPassRegisterRadar;
 * Result: BLUFOR batteries answer enemy artillery fire detected by this radar.
 *
 * Repeat/JIP: replaces the same object entry; removal is repeat-safe. Public registry reaches JIP.
 * Current callers: mission Eden init fields, scripts and authenticated AI radar ZEN setup.
 */

params [["_object", objNull, [objNull]], ["_side", sideUnknown, [sideUnknown, ""]], ["_enabled", true, [true]]];
if (isNull _object) exitWith {false};
if (!isServer || {remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}}) exitWith {false};
if (_side isEqualType sideUnknown) then {
    if (_side == sideUnknown) then {_side = side _object};
    _side = switch (_side) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
};
_side = toUpperANSI _side;
if (!(_side in ["WEST", "EAST", "GUER", "CIV"]) || {_enabled && {!alive _object}}) exitWith {false};
private _radars = (missionNamespace getVariable ["Waldo_AIPass_CounterBatteryRadars", []]) select {alive (_x select 0) && {(_x select 0) != _object}};
if (_enabled) then {_radars pushBack [_object, _side]};
missionNamespace setVariable ["Waldo_AIPass_CounterBatteryRadars", _radars, true];
true

/*
 * Author: Waldo
 * Copies the recorded WMP scale from one object to another.
 *
 * Arguments:
 * 0: source <OBJECT>
 * 1: target <OBJECT>
 *
 * Return Value:
 * Object - scaled target or objNull
 */

params [["_source", objNull, [objNull]], ["_target", objNull, [objNull]]];
if (isNull _source || {isNull _target}) exitWith {objNull};
[_target, _source getVariable ["Waldo_ObjectScale", 1], false] call Waldo_fnc_ObjectScale

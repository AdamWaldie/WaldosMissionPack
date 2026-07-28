/*
 * Author: Waldo
 * Multiplies an object's recorded current WMP scale by a factor.
 *
 * Arguments:
 * 0: object <OBJECT>
 * 1: multiplier <NUMBER>
 *
 * Return Value:
 * Object - scaled object or objNull
 */

params [["_object", objNull, [objNull]], ["_multiplier", 1, [0]]];
if (isNull _object) exitWith {objNull};
[_object, (_object getVariable ["Waldo_ObjectScale", 1]) * _multiplier, false] call Waldo_fnc_ObjectScale

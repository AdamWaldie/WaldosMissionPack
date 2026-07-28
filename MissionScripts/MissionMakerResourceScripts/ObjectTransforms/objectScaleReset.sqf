/*
 * Author: Waldo
 * Restores an object's recorded pre-WMP scale.
 *
 * Arguments:
 * 0: object <OBJECT>
 *
 * Return Value:
 * Object - reset object or objNull
 */

params [["_object", objNull, [objNull]]];
if (isNull _object) exitWith {objNull};
[_object, _object getVariable ["Waldo_ObjectScaleOriginal", 1], false] call Waldo_fnc_ObjectScale

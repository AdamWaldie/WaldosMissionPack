/*
 * Author: WaldoTheWarfighter
 * Restores an object's recorded pre-WMP scale.
 *
 * The original scale is captured by Waldo_fnc_ObjectScale before its first successful change.
 * This function expects the supplied object to remain a Simple Object or attached object. It is
 * currently called by the full-pack audit station and available to mission scripts.
 *
 * Arguments:
 * 0: object <OBJECT>
 *
 * Return Value:
 * Object - reset object or objNull
 *
 * Example:
 * [decorativeProp] call Waldo_fnc_ObjectScaleReset;
 */

params [["_object", objNull, [objNull]]];
if (isNull _object) exitWith {objNull};
[_object, _object getVariable ["Waldo_ObjectScaleOriginal", 1], false] call Waldo_fnc_ObjectScale

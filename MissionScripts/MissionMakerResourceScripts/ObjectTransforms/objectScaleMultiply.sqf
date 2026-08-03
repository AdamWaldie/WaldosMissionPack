/*
 * Author: WaldoTheWarfighter
 * Multiplies an object's actual engine render scale by a factor.
 *
 * This delegates validation, server authority and supported-object handling to
 * Waldo_fnc_ObjectScale. It does not convert an unsupported ordinary object; call ObjectScale
 * with conversion first. Currently called by the full-pack audit station and mission scripts.
 *
 * Arguments:
 * 0: object <OBJECT>
 * 1: multiplier <NUMBER>
 *
 * Return Value:
 * Object - scaled object or objNull
 *
 * Example:
 * [decorativeProp, 1.25] call Waldo_fnc_ObjectScaleMultiply;
 */

params [["_object", objNull, [objNull]], ["_multiplier", 1, [0]]];
if (isNull _object) exitWith {objNull};
[_object, (getObjectScale _object) * _multiplier, false] call Waldo_fnc_ObjectScale

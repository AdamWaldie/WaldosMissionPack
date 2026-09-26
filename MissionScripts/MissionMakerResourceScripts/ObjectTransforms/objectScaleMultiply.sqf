/*
 * Author: WaldoTheWarfighter
 * Multiplies an object's actual engine render scale by a factor.
 * Locality and authority: Reads the current scale where called; Waldo_fnc_ObjectScale validates
 * and applies the resulting scale on the server.
 * Repeat/JIP: Each call multiplies again, so repeating it changes the result. The object's
 * resulting shared state reaches JIP; no separate client setup is installed.
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
 * Result: The server returns the scaled Object or objNull. A client-forwarded result is not a
 * server success confirmation.
 * Current callers: Mission scripts using Waldo_fnc_ObjectScaleMultiply and the full-pack audit station.
 */

params [["_object", objNull, [objNull]], ["_multiplier", 1, [0]]];
if (isNull _object) exitWith {objNull};
[_object, (getObjectScale _object) * _multiplier, false] call Waldo_fnc_ObjectScale

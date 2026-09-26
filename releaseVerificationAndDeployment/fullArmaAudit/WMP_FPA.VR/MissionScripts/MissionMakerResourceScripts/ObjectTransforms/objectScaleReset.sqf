/*
 * Author: WaldoTheWarfighter
 * Restores an object's recorded pre-WMP scale.
 * Locality and authority: Reads the public original-scale variable and delegates mutation to
 * server-authoritative Waldo_fnc_ObjectScale.
 * Repeat/JIP: Repeated calls use the recorded original value. The object's shared scale state
 * reaches JIP; no player-local setup is installed.
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
 * Result: The server returns the reset Object or objNull. A client-forwarded call does not
 * confirm the server result synchronously.
 * Current callers: Mission scripts using Waldo_fnc_ObjectScaleReset and the full-pack audit station.
 */

params [["_object", objNull, [objNull]]];
if (isNull _object) exitWith {objNull};
[_object, _object getVariable ["Waldo_ObjectScaleOriginal", 1], false] call Waldo_fnc_ObjectScale

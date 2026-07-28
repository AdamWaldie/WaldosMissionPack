/*
 * Author: Waldo
 * Registers a moving object as a contact/proximity hazard emitter.
 *
 * Arguments: 0: key <STRING>; 1: emitter <OBJECT>; 2: radius <NUMBER>; 3: profile <HASHMAP>
 * Return Value: Boolean
 */

params ["_key", ["_emitter", objNull, [objNull]], ["_radius", 3, [0]], ["_profile", createHashMap, [createHashMap]]];
if (isNull _emitter) exitWith {false};
_profile set ["emitterRadius", _radius max 0.5];
[_key, _emitter, _profile] call Waldo_fnc_HazardRegisterZone

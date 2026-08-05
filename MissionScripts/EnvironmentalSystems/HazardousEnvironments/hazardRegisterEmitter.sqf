/*
 * Author: WaldoTheWarfighter, Val
 * Registers a moving object as a contact/proximity hazard emitter.
 *
 * This adapter stores emitterRadius in the supplied profile and delegates registration/locality to
 * Waldo_fnc_HazardRegisterZone. It is currently called directly by mission scripts and inventoried
 * by the full-pack function station.
 * Locality and authority: Call on the server. The function adapts an object/radius into a zone and
 * delegates validation, authoritative storage and publication to Waldo_fnc_HazardRegisterZone.
 *
 * Arguments:
 * 0: key <STRING> - stable unique zone name
 * 1: emitter <OBJECT> - moving source object
 * 2: radius <NUMBER> - detection radius in metres (default: 3)
 * 3: profile <HASHMAP> - hazard settings
 *
 * Return Value:
 * Boolean - true when the emitter was registered
 *
 * Example:
 * ["leaking_truck", truck1, 8, _profile] call Waldo_fnc_HazardRegisterEmitter;
 * Result: Registers or replaces `leaking_truck` as an 8 m moving hazard around `truck1`.
 * Current callers: server mission scripts and the full-pack audit function station.
 */

params ["_key", ["_emitter", objNull, [objNull]], ["_radius", 3, [0]], ["_profile", createHashMap, [createHashMap]]];
if (isNull _emitter) exitWith {false};
_profile set ["emitterRadius", _radius max 0.5];
[_key, _emitter, _profile] call Waldo_fnc_HazardRegisterZone

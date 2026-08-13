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
private _registered = [_key, _emitter, _profile] call Waldo_fnc_HazardRegisterZone;
// A moving emitter can be destroyed/deleted mid-mission (wreck cleanup, a scripted deleteVehicle)
// without anything unregistering its zone, leaving a permanently inert entry in the registry that
// every client keeps evaluating every tick. Auto-unregister the zone once, the same lifecycle
// Waldo_Jamming_Destructible already applies to jammer emitters.
if (_registered) then {
    _emitter addEventHandler ["Deleted", {
        params ["_entity"];
        [_entity getVariable ["Waldo_Hazard_EmitterKey", ""]] call Waldo_fnc_HazardUnregisterZone;
    }];
    _emitter setVariable ["Waldo_Hazard_EmitterKey", _key];
};
_registered

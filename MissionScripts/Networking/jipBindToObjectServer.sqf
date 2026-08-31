/*
 * Author: WaldoTheWarfighter
 * Binds one named remote-execution JIP entry to a world object's lifetime. Named entries are used
 * when an object needs more than one persistent setup call, because Arma provides only one
 * replaceable object-keyed JIP slot per object. The object's server-side Deleted handler removes
 * every bound named entry from the engine JIP queue.
 *
 * Locality/authority: server-only lifecycle bookkeeping. It does not execute or republish payloads.
 * Repeat/JIP behaviour: repeat-safe for the same object/id; one Deleted handler owns all bound ids.
 *
 * Arguments:
 * 0: lifetime object <OBJECT>
 * 1: named JIP id <STRING>
 * Return Value: BOOLEAN - true when bound; false for invalid/non-server calls.
 * Current callers: starter crates, Field Resupply hubs/crates and Tactical Displays.
 * Example: [_crate, "Waldo_StarterCrate_1:42"] call Waldo_fnc_JipBindToObjectServer;
 */

params [
    ["_object", objNull, [objNull]],
    ["_jipId", "", [""]]
];
if (!isServer || {isNull _object} || {_jipId == ""}) exitWith {false};

private _ids = _object getVariable ["Waldo_Network_BoundJipIds", []];
_ids pushBackUnique _jipId;
_object setVariable ["Waldo_Network_BoundJipIds", _ids];
if (isNil {_object getVariable "Waldo_Network_BoundJipDeletedEH"}) then {
    private _handler = _object addEventHandler ["Deleted", {
        params ["_deletedObject"];
        {
            remoteExec ["", _x];
        } forEach (_deletedObject getVariable ["Waldo_Network_BoundJipIds", []]);
    }];
    _object setVariable ["Waldo_Network_BoundJipDeletedEH", _handler];
};
true

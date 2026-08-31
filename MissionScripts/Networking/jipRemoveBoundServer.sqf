/*
 * Author: WaldoTheWarfighter
 * Removes one named remote-execution JIP entry and detaches that id from its source object's
 * deletion cleanup list. This is used when a feature explicitly removes an action before the
 * source object itself is deleted.
 *
 * Locality/authority: server-only engine JIP lifecycle mutation.
 * Repeat/JIP behaviour: repeat-safe; removing a missing queue/list entry is harmless.
 *
 * Arguments:
 * 0: lifetime object <OBJECT>
 * 1: named JIP id <STRING>
 * Return Value: BOOLEAN - true when a valid removal was issued.
 * Current caller: Waldo_fnc_EcoCore_clearZeusObjectAction.
 * Example: [_terminal, _jipId] call Waldo_fnc_JipRemoveBoundServer;
 */

params [
    ["_object", objNull, [objNull]],
    ["_jipId", "", [""]]
];
if (!isServer || {_jipId == ""}) exitWith {false};

remoteExec ["", _jipId];
if (!isNull _object) then {
    private _ids = _object getVariable ["Waldo_Network_BoundJipIds", []];
    private _index = _ids find _jipId;
    if (_index >= 0) then {
        _ids deleteAt _index;
        _object setVariable ["Waldo_Network_BoundJipIds", _ids];
    };
};
true

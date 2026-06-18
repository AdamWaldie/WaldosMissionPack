/*
 * Author: Waldo
 * Register curator editable objects.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _objects <ARRAY> - objects (optional, default: [])
 * 1: _addCrew <BOOL> - add crew (optional, default: true)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_objects, _addCrew] call Waldo_fnc_EcoCore_registerCuratorEditableObjects;
 */

    params [["_objects", []], ["_addCrew", true]];

    private _validObjects = _objects select {!isNull _x};
    if ((count _validObjects) <= 0) exitWith {};

    {
        if (isNull _x) then {continue;};

        if (isServer) then {
            _x addCuratorEditableObjects [_validObjects, _addCrew];
        } else {
            [_x, [_validObjects, _addCrew]] remoteExec ["addCuratorEditableObjects", 2];
        };
    } forEach allCurators;

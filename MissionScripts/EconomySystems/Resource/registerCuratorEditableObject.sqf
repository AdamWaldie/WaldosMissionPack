/*
 * Author: Waldo
 * Register curator editable object.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _object <OBJECT> - object (optional, default: objNull)
 * 1: _addCrew <BOOL> - add crew (optional, default: true)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_object, _addCrew] call Waldo_fnc_EcoResource_registerCuratorEditableObject;
 */

    params [["_object", objNull], ["_addCrew", true]];

    if (isNull _object) exitWith {};

    {
        if (isNull _x) then {continue;};

        if (isServer) then {
            _x addCuratorEditableObjects [[_object], _addCrew];
        } else {
            [_x, [[_object], _addCrew]] remoteExec ["addCuratorEditableObjects", 2];
        };
    } forEach allCurators;

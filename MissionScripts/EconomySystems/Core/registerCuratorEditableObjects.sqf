/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - registerCuratorEditableObjects
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_registerCuratorEditableObjects via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - registerCuratorEditableObject
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_registerCuratorEditableObject via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

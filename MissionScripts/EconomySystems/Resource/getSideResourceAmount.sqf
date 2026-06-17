/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getSideResourceAmount
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getSideResourceAmount via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_sideKey", "_resourceType"];

    private _varName = [_sideKey] call Waldo_fnc_EcoResource_getSideStorageVar;
    if (_varName isEqualTo "") exitWith {0};

    private _rows = missionNamespace getVariable [_varName, []];
    private _index = _rows findIf {
        ((_x param [0, ""]) isEqualTo _resourceType)
    };

    if (_index < 0) exitWith {0};
    (_rows select _index) param [1, 0]

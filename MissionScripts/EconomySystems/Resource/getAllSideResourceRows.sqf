/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getAllSideResourceRows
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getAllSideResourceRows via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    private _result = [];

    {
        private _varName = [_x] call Waldo_fnc_EcoResource_getSideStorageVar;
        private _rows = +(missionNamespace getVariable [_varName, []]);
        _result pushBack [_x, _rows];
    } forEach ["WEST", "EAST", "GUER", "CIV"];

    _result

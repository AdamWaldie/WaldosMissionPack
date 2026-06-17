/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getResourceBaseStorage
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getResourceBaseStorage via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_resourceType"];

    private _def = [_resourceType] call Waldo_fnc_EcoResource_getResourceDefinition;
    if ((count _def) <= 3) exitWith {-1};
    private _baseStorage = _def param [3, -1];
    if (_baseStorage <= 0) exitWith {-1};
    _baseStorage

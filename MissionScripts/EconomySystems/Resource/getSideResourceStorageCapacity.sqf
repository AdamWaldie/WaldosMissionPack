/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getSideResourceStorageCapacity
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getSideResourceStorageCapacity via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_sideKey", "_resourceType"];

    private _baseStorage = [_resourceType] call Waldo_fnc_EcoResource_getResourceBaseStorage;
    if (_baseStorage <= 0) exitWith {-1};

    _baseStorage + ([_sideKey, _resourceType] call Waldo_fnc_EcoResource_getSideStorageBonus)

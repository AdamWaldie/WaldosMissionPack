/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getAllowedResourceGain
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getAllowedResourceGain via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_sideKey", "_resourceType", ["_requestedAmount", 0]];

    private _amount = 0 max (floor _requestedAmount);
    if (_amount <= 0) exitWith {0};

    private _capacity = [_sideKey, _resourceType] call Waldo_fnc_EcoResource_getSideResourceStorageCapacity;
    if (_capacity < 0) exitWith {_amount};

    private _current = [_sideKey, _resourceType] call Waldo_fnc_EcoResource_getSideResourceAmount;
    private _headroom = _capacity - _current;
    if (_headroom <= 0) exitWith {0};

    _amount min _headroom

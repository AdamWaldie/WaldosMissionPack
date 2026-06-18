/*
 * Author: Waldo
 * Get allowed resource gain.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _resourceType <ANY> - resource type
 * 2: _requestedAmount <SCALAR> - requested amount (optional, default: 0)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey, _resourceType, _requestedAmount] call Waldo_fnc_EcoResource_getAllowedResourceGain;
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

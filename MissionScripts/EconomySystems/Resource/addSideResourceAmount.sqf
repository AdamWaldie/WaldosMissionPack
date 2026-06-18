/*
 * Author: Waldo
 * Add side resource amount.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _resourceType <ANY> - resource type
 * 2: _delta <SCALAR> - delta (optional, default: 0)
 * 3: _callerName <STRING> - caller name (optional, default: "Zeus")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_sideKey, _resourceType, _delta, _callerName] call Waldo_fnc_EcoResource_addSideResourceAmount;
 */

    params ["_sideKey", "_resourceType", ["_delta", 0], ["_callerName", "Zeus"]];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _safeDelta = floor _delta;
    if (_safeDelta > 0) then {
        _safeDelta = [_sideKey, _resourceType, _safeDelta] call Waldo_fnc_EcoResource_getAllowedResourceGain;
    };

    if (_safeDelta isEqualTo 0) exitWith {};

    private _current = [_sideKey, _resourceType] call Waldo_fnc_EcoResource_getSideResourceAmount;
    [_sideKey, _resourceType, _current + _safeDelta, _callerName] call Waldo_fnc_EcoResource_setSideResourceAmount;

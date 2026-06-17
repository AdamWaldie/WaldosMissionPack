/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - addSideResourceAmount
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_addSideResourceAmount via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

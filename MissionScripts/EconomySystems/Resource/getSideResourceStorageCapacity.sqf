/*
 * Author: Waldo
 * Get side resource storage capacity.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _resourceType <ANY> - resource type
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey, _resourceType] call Waldo_fnc_EcoResource_getSideResourceStorageCapacity;
 */

    params ["_sideKey", "_resourceType"];

    private _baseStorage = [_resourceType] call Waldo_fnc_EcoResource_getResourceBaseStorage;
    if (_baseStorage <= 0) exitWith {-1};

    _baseStorage + ([_sideKey, _resourceType] call Waldo_fnc_EcoResource_getSideStorageBonus)

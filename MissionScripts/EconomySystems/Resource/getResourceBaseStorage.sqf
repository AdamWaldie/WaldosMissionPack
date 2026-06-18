/*
 * Author: Waldo
 * Get resource base storage.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _resourceType <ANY> - resource type
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_resourceType] call Waldo_fnc_EcoResource_getResourceBaseStorage;
 */

    params ["_resourceType"];

    private _def = [_resourceType] call Waldo_fnc_EcoResource_getResourceDefinition;
    if ((count _def) <= 3) exitWith {-1};
    private _baseStorage = _def param [3, -1];
    if (_baseStorage <= 0) exitWith {-1};
    _baseStorage

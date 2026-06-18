/*
 * Author: Waldo
 * Get resource marker class.
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
 * [_resourceType] call Waldo_fnc_EcoResource_getResourceMarkerClass;
 */

    params ["_resourceType"];

    private _def = [_resourceType] call Waldo_fnc_EcoResource_getResourceDefinition;
    private _icon = if ((count _def) > 2) then {_def param [2, ""]} else {""};
    [_icon] call Waldo_fnc_EcoResource_getMarkerClassForIconPath

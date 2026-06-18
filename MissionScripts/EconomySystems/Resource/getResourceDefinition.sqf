/*
 * Author: Waldo
 * Get resource definition.
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
 * [_resourceType] call Waldo_fnc_EcoResource_getResourceDefinition;
 */

    params ["_resourceType"];

    private _catalog = call Waldo_fnc_EcoResource_getResourceCatalog;
    private _index = _catalog findIf {
        ((_x param [0, ""]) isEqualTo _resourceType)
    };

    if (_index < 0) exitWith {[]};
    +(_catalog select _index)

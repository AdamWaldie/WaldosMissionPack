/*
 * Author: Waldo
 * Get resource catalog.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoResource_getResourceCatalog;
 */

    private _catalog = +(missionNamespace getVariable ["WaldoEcoResource_ResourceCatalog", []]);
    if ((count _catalog) isEqualTo 0) then {
        _catalog = [["Resource", call Waldo_fnc_EcoResource_getDefaultResourceColor, call Waldo_fnc_EcoResource_getDefaultResourceIcon, -1]];
    };
    _catalog

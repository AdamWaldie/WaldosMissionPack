/*
 * Author: Waldo
 * Get resource types.
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
 * [] call Waldo_fnc_EcoResource_getResourceTypes;
 */

    (call Waldo_fnc_EcoResource_getResourceCatalog) apply {_x param [0, "Resource"]}

/*
 * Author: Waldo
 * Get resource marker visibility alpha.
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
 * [] call Waldo_fnc_EcoResource_getResourceMarkerVisibilityAlpha;
 */

    [0, 1] select (missionNamespace getVariable ["WaldoEcoResource_ResourceMarkersVisible", true])

/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getResourceMarkerVisibilityAlpha
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getResourceMarkerVisibilityAlpha via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    [0, 1] select (missionNamespace getVariable ["WaldoEcoResource_ResourceMarkersVisible", true])

/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - setResourceMarkerVisibility
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_setResourceMarkerVisibility via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_visible", true], ["_callerName", "Zeus"]];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    missionNamespace setVariable ["WaldoEcoResource_ResourceMarkersVisible", _visible, true];
    [] call Waldo_fnc_EcoResource_applyResourceMarkerVisibilityGlobal;

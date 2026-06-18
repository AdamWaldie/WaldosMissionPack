/*
 * Author: Waldo
 * Set resource marker visibility.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _visible <BOOL> - visible (optional, default: true)
 * 1: _callerName <STRING> - caller name (optional, default: "Zeus")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_visible, _callerName] call Waldo_fnc_EcoResource_setResourceMarkerVisibility;
 */

    params [["_visible", true], ["_callerName", "Zeus"]];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    missionNamespace setVariable ["WaldoEcoResource_ResourceMarkersVisible", _visible, true];
    [] call Waldo_fnc_EcoResource_applyResourceMarkerVisibilityGlobal;

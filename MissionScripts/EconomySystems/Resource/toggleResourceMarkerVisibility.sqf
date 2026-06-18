/*
 * Author: Waldo
 * Toggle resource marker visibility.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _callerName <STRING> - caller name (optional, default: "Zeus")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_callerName] call Waldo_fnc_EcoResource_toggleResourceMarkerVisibility;
 */

    params [["_callerName", "Zeus"]];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _current = missionNamespace getVariable ["WaldoEcoResource_ResourceMarkersVisible", true];
    [!_current, _callerName] call Waldo_fnc_EcoResource_setResourceMarkerVisibility;

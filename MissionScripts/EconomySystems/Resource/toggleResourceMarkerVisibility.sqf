/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - toggleResourceMarkerVisibility
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_toggleResourceMarkerVisibility via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_callerName", "Zeus"]];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _current = missionNamespace getVariable ["WaldoEcoResource_ResourceMarkersVisible", true];
    [!_current, _callerName] call Waldo_fnc_EcoResource_setResourceMarkerVisibility;

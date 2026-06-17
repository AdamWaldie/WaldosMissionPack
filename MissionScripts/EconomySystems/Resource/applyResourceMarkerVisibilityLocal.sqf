/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - applyResourceMarkerVisibilityLocal
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_applyResourceMarkerVisibilityLocal via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if (!hasInterface) exitWith {};

    private _visible = missionNamespace getVariable ["WaldoEcoResource_ResourceMarkersVisible", true];
    private _alpha = [0, 1] select _visible;

    {
        _x setMarkerAlphaLocal _alpha;
    } forEach (call Waldo_fnc_EcoResource_getActiveResourceMarkers);

/*
 * Author: Waldo
 * Apply resource marker visibility local.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoResource_applyResourceMarkerVisibilityLocal;
 */

    if (!hasInterface) exitWith {};

    private _visible = missionNamespace getVariable ["WaldoEcoResource_ResourceMarkersVisible", true];
    private _alpha = [0, 1] select _visible;

    {
        _x setMarkerAlphaLocal _alpha;
    } forEach (call Waldo_fnc_EcoResource_getActiveResourceMarkers);

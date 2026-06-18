/*
 * Author: Waldo
 * Apply resource marker visibility global.
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
 * [] call Waldo_fnc_EcoResource_applyResourceMarkerVisibilityGlobal;
 */

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _alpha = call Waldo_fnc_EcoResource_getResourceMarkerVisibilityAlpha;
    {
        if !(_x isEqualType "") then {continue;};
        if (_x isEqualTo "") then {continue;};
        if ((markerType _x) isEqualTo "") then {continue;};

        _x setMarkerAlpha _alpha;
    } forEach (call Waldo_fnc_EcoResource_getActiveResourceMarkers);

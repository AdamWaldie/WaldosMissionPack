/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - applyResourceMarkerVisibilityGlobal
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_applyResourceMarkerVisibilityGlobal via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _alpha = call Waldo_fnc_EcoResource_getResourceMarkerVisibilityAlpha;
    {
        if !(_x isEqualType "") then {continue;};
        if (_x isEqualTo "") then {continue;};
        if ((markerType _x) isEqualTo "") then {continue;};

        _x setMarkerAlpha _alpha;
    } forEach (call Waldo_fnc_EcoResource_getActiveResourceMarkers);

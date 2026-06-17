/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - deleteAllTrackedMarkers
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_deleteAllTrackedMarkers via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    {
        deleteMarker _x;
    } forEach (call Waldo_fnc_EcoResource_getActiveResourceMarkers);

    missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", [], true];

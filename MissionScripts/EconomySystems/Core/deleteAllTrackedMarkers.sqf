/*
 * Author: Waldo
 * Delete all tracked markers.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_deleteAllTrackedMarkers;
 */

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    {
        deleteMarker _x;
    } forEach (call Waldo_fnc_EcoResource_getActiveResourceMarkers);

    missionNamespace setVariable ["WaldoEcoResource_ActiveResourceMarkers", [], true];

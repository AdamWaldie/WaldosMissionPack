/*
 * Author: Waldo
 * Purge resource containers.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_purgeResourceContainers;
 */

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    {
        if (isNull _x) then {continue;};
        if !(_x getVariable ["WaldoEcoResource_IsResourceCrate", false]) then {continue;};
        [_x] call Waldo_fnc_EcoResource_deleteCrateMarker;
        deleteVehicle _x;
    } forEach (allMissionObjects "Land_PlasticCase_01_medium_F");

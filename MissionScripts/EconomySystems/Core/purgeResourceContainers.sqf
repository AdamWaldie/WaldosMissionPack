/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - purgeResourceContainers
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_purgeResourceContainers via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    {
        if (isNull _x) then {continue;};
        if !(_x getVariable ["WaldoEcoResource_IsResourceCrate", false]) then {continue;};
        [_x] call Waldo_fnc_EcoResource_deleteCrateMarker;
        deleteVehicle _x;
    } forEach (allMissionObjects "Land_PlasticCase_01_medium_F");

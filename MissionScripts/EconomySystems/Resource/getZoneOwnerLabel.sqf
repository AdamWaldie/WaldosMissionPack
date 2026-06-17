/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getZoneOwnerLabel
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getZoneOwnerLabel via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_sideKey"];

    switch (toUpper _sideKey) do {
        case "WEST": {"BLUFOR"};
        case "EAST": {"OPFOR"};
        case "GUER": {"INDEP"};
        default {"UNCLAIMED"};
    }

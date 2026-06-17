/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getSideStorageVar
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getSideStorageVar via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_sideKey"];

    switch (toUpper _sideKey) do {
        case "WEST": {"WaldoEcoResource_Resources_WEST"};
        case "EAST": {"WaldoEcoResource_Resources_EAST"};
        case "GUER": {"WaldoEcoResource_Resources_GUER"};
        case "CIV": {"WaldoEcoResource_Resources_CIV"};
        default {""};
    };

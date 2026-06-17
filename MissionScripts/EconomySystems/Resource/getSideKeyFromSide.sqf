/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getSideKeyFromSide
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getSideKeyFromSide via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_side"];

    switch (_side) do {
        case west: {"WEST"};
        case east: {"EAST"};
        case independent: {"GUER"};
        case civilian: {"CIV"};
        default {"CIV"};
    };

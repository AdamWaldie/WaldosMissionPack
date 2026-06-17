/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - setPresetGenericComplexity
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_setPresetGenericComplexity via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_complexityKey", ""]];
    missionNamespace setVariable ["WaldoEcoCore_PresetGenericComplexity", toUpper _complexityKey, true];

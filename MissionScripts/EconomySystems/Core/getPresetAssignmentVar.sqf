/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - getPresetAssignmentVar
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_getPresetAssignmentVar via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_sideKey", ""]];

    switch (toUpper _sideKey) do {
        case "WEST": {"WaldoEcoCore_PresetAssignment_WEST"};
        case "EAST": {"WaldoEcoCore_PresetAssignment_EAST"};
        case "GUER": {"WaldoEcoCore_PresetAssignment_GUER"};
        default {""};
    }

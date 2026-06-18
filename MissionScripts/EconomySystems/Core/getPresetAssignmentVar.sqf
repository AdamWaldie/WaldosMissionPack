/*
 * Author: Waldo
 * Get preset assignment var.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoCore_getPresetAssignmentVar;
 */

    params [["_sideKey", ""]];

    switch (toUpper _sideKey) do {
        case "WEST": {"WaldoEcoCore_PresetAssignment_WEST"};
        case "EAST": {"WaldoEcoCore_PresetAssignment_EAST"};
        case "GUER": {"WaldoEcoCore_PresetAssignment_GUER"};
        default {""};
    }

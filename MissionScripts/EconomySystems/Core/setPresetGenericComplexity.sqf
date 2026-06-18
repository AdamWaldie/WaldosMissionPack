/*
 * Author: Waldo
 * Set preset generic complexity.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _complexityKey <STRING> - complexity key (optional, default: "")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_complexityKey] call Waldo_fnc_EcoCore_setPresetGenericComplexity;
 */

    params [["_complexityKey", ""]];
    missionNamespace setVariable ["WaldoEcoCore_PresetGenericComplexity", toUpper _complexityKey, true];

/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - cleanupUnifiedPresetPrompt
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_cleanupUnifiedPresetPrompt via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {};

    [_disp, "WaldoEcoCore_PresetInputTargets"] call Waldo_fnc_EcoCore_resetPromptInputTargets;
    [_disp, [
        "WaldoEcoCore_PresetBG",
        "WaldoEcoCore_PresetTitle",
        "WaldoEcoCore_PresetComplexityLabel",
        "WaldoEcoCore_PresetComplexityCombo",
        "WaldoEcoCore_PresetBluforLabel",
        "WaldoEcoCore_PresetBluforCombo",
        "WaldoEcoCore_PresetOpforLabel",
        "WaldoEcoCore_PresetOpforCombo",
        "WaldoEcoCore_PresetIndepLabel",
        "WaldoEcoCore_PresetIndepCombo",
        "WaldoEcoCore_PresetNote",
        "WaldoEcoCore_PresetStatus",
        "WaldoEcoCore_PresetSet",
        "WaldoEcoCore_PresetClose"
    ]] call Waldo_fnc_EcoCore_deleteDisplayControlsByVars;

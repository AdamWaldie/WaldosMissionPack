/*
 * Author: Waldo
 * Cleanup unified preset prompt.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoCore_cleanupUnifiedPresetPrompt;
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

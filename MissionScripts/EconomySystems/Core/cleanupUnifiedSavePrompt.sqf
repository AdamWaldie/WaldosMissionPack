/*
 * Author: Waldo
 * Cleanup unified save prompt.
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
 * [_disp] call Waldo_fnc_EcoCore_cleanupUnifiedSavePrompt;
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {};

    [_disp, "WaldoEcoCore_SaveInputTargets"] call Waldo_fnc_EcoCore_resetPromptInputTargets;
    [_disp, [
        "WaldoEcoCore_SaveBG",
        "WaldoEcoCore_SaveTitle",
        "WaldoEcoCore_SaveResourcesCheck",
        "WaldoEcoCore_SaveResourcesLabel",
        "WaldoEcoCore_SaveResearchCheck",
        "WaldoEcoCore_SaveResearchLabel",
        "WaldoEcoCore_SaveBuildingsCheck",
        "WaldoEcoCore_SaveBuildingsLabel",
        "WaldoEcoCore_SaveBuyCheck",
        "WaldoEcoCore_SaveBuyLabel",
        "WaldoEcoCore_SaveAdditiveCheck",
        "WaldoEcoCore_SaveAdditiveLabel",
        "WaldoEcoCore_SaveText",
        "WaldoEcoCore_SaveImport",
        "WaldoEcoCore_SaveExport",
        "WaldoEcoCore_SaveClose"
    ]] call Waldo_fnc_EcoCore_deleteDisplayControlsByVars;
    [_disp] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;

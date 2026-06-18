/*
 * Author: Waldo
 * Cleanup unified purge prompt.
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
 * [_disp] call Waldo_fnc_EcoCore_cleanupUnifiedPurgePrompt;
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {};

    [_disp, "WaldoEcoCore_PurgeInputTargets"] call Waldo_fnc_EcoCore_resetPromptInputTargets;
    [_disp, [
        "WaldoEcoCore_PurgeBG",
        "WaldoEcoCore_PurgeTitle",
        "WaldoEcoCore_PurgeConfigHeader",
        "WaldoEcoCore_PurgeConfigCheckAll",
        "WaldoEcoCore_PurgeConfigResourcesCheck",
        "WaldoEcoCore_PurgeConfigResourcesLabel",
        "WaldoEcoCore_PurgeConfigBuildingsCheck",
        "WaldoEcoCore_PurgeConfigBuildingsLabel",
        "WaldoEcoCore_PurgeConfigResearchCheck",
        "WaldoEcoCore_PurgeConfigResearchLabel",
        "WaldoEcoCore_PurgeConfigBuyCheck",
        "WaldoEcoCore_PurgeConfigBuyLabel",
        "WaldoEcoCore_PurgeValuesHeader",
        "WaldoEcoCore_PurgeValuesCheckAll",
        "WaldoEcoCore_PurgeValuesBuildingsCheck",
        "WaldoEcoCore_PurgeValuesBuildingsLabel",
        "WaldoEcoCore_PurgeValuesResourcesCheck",
        "WaldoEcoCore_PurgeValuesResourcesLabel",
        "WaldoEcoCore_PurgeValuesContainersCheck",
        "WaldoEcoCore_PurgeValuesContainersLabel",
        "WaldoEcoCore_PurgeValuesGroundCommandCheck",
        "WaldoEcoCore_PurgeValuesGroundCommandLabel",
        "WaldoEcoCore_PurgeModuleCheck",
        "WaldoEcoCore_PurgeModuleLabel",
        "WaldoEcoCore_PurgeWarning",
        "WaldoEcoCore_PurgeButton",
        "WaldoEcoCore_PurgeCancel"
    ]] call Waldo_fnc_EcoCore_deleteDisplayControlsByVars;

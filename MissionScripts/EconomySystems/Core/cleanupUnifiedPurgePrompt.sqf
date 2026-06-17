/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - cleanupUnifiedPurgePrompt
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_cleanupUnifiedPurgePrompt via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

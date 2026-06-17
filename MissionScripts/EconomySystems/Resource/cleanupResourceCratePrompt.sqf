/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - cleanupResourceCratePrompt
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_cleanupResourceCratePrompt via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {};

    [_disp, "WaldoEcoResource_InputTargets"] call Waldo_fnc_EcoCore_resetPromptInputTargets;
    [_disp, [
        "WaldoEcoResource_ValuePromptBG",
        "WaldoEcoResource_ValuePromptTitle",
        "WaldoEcoResource_ValuePromptResourcesLabel",
        "WaldoEcoResource_ValuePromptResourcesEdit",
        "WaldoEcoResource_ValuePromptOK",
        "WaldoEcoResource_ValuePromptCancel"
    ]] call Waldo_fnc_EcoCore_deleteDisplayControlsByVars;

    _disp setVariable ["WaldoEcoResource_TargetPos", nil];
    [_disp] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;

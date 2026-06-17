/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - cleanupResourceSettingsPrompt
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_cleanupResourceSettingsPrompt via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {};

    [_disp, "WaldoEcoResource_InputTargets"] call Waldo_fnc_EcoCore_resetPromptInputTargets;
    [_disp, [
        "WaldoEcoResource_SettingsBG",
        "WaldoEcoResource_SettingsTitle",
        "WaldoEcoResource_SettingsSideLabel",
        "WaldoEcoResource_SettingsBLUFOR",
        "WaldoEcoResource_SettingsOPFOR",
        "WaldoEcoResource_SettingsINDFOR",
        "WaldoEcoResource_SettingsTypeLabel",
        "WaldoEcoResource_SettingsTypePrev",
        "WaldoEcoResource_SettingsTypeValue",
        "WaldoEcoResource_SettingsTypeNext",
        "WaldoEcoResource_SettingsCurrentLabel",
        "WaldoEcoResource_SettingsCurrentValue",
        "WaldoEcoResource_SettingsAmountLabel",
        "WaldoEcoResource_SettingsAmountEdit",
        "WaldoEcoResource_SettingsApply",
        "WaldoEcoResource_SettingsClose"
    ]] call Waldo_fnc_EcoCore_deleteDisplayControlsByVars;

    _disp setVariable ["WaldoEcoResource_SettingsSelectedSide", nil];
    _disp setVariable ["WaldoEcoResource_SettingsTypeIndex", nil];
    [_disp] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;

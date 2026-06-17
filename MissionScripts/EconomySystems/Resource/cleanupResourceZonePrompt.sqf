/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - cleanupResourceZonePrompt
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_cleanupResourceZonePrompt via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {};

    [_disp, "WaldoEcoResource_InputTargets"] call Waldo_fnc_EcoCore_resetPromptInputTargets;
    [_disp, [
        "WaldoEcoResource_ZoneBG",
        "WaldoEcoResource_ZoneTitle",
        "WaldoEcoResource_ZoneNameLabel",
        "WaldoEcoResource_ZoneNameEdit",
        "WaldoEcoResource_ZoneSizeLabel",
        "WaldoEcoResource_ZoneSizeEdit",
        "WaldoEcoResource_ZoneOwnerLabel",
        "WaldoEcoResource_ZoneOwnerPrev",
        "WaldoEcoResource_ZoneOwnerValue",
        "WaldoEcoResource_ZoneOwnerNext",
        "WaldoEcoResource_ZoneResourcesLabel",
        "WaldoEcoResource_ZoneResourcesEdit",
        "WaldoEcoResource_ZoneIntervalLabel",
        "WaldoEcoResource_ZoneIntervalEdit",
        "WaldoEcoResource_ZoneCreate",
        "WaldoEcoResource_ZoneCancel"
    ]] call Waldo_fnc_EcoCore_deleteDisplayControlsByVars;

    _disp setVariable ["WaldoEcoResource_ZoneTargetPos", nil];
    _disp setVariable ["WaldoEcoResource_ZoneOwnerIndex", nil];
    [_disp] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;

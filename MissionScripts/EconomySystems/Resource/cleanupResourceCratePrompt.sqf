/*
 * Author: Waldo
 * Cleanup resource crate prompt.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoResource_cleanupResourceCratePrompt;
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

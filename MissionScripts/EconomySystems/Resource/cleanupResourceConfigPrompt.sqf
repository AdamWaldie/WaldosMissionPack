/*
 * Author: Waldo
 * Cleanup resource config prompt.
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
 * [_disp] call Waldo_fnc_EcoResource_cleanupResourceConfigPrompt;
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {};

    [_disp, "WaldoEcoResource_InputTargets"] call Waldo_fnc_EcoCore_resetPromptInputTargets;
    [_disp, [
        "WaldoEcoResource_ConfigBG",
        "WaldoEcoResource_ConfigTitle",
        "WaldoEcoResource_ConfigListLabel",
        "WaldoEcoResource_ConfigList",
        "WaldoEcoResource_ConfigNameLabel",
        "WaldoEcoResource_ConfigNameEdit",
        "WaldoEcoResource_ConfigColorLabel",
        "WaldoEcoResource_ConfigColorEdit",
        "WaldoEcoResource_ConfigBaseStorageLabel",
        "WaldoEcoResource_ConfigBaseStorageEdit",
        "WaldoEcoResource_ConfigIconLabel",
        "WaldoEcoResource_ConfigIconPrev",
        "WaldoEcoResource_ConfigIconValue",
        "WaldoEcoResource_ConfigIconNext",
        "WaldoEcoResource_ConfigAdd",
        "WaldoEcoResource_ConfigRemove",
        "WaldoEcoResource_ConfigSave",
        "WaldoEcoResource_ConfigClose"
    ]] call Waldo_fnc_EcoCore_deleteDisplayControlsByVars;
    [_disp] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;

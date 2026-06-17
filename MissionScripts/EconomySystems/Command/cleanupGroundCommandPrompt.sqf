/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCommand system - cleanupGroundCommandPrompt
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCommand_cleanupGroundCommandPrompt via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {};

    [_disp, [
        "WaldoEcoCommand_PromptBG",
        "WaldoEcoCommand_PromptTitle",
        "WaldoEcoCommand_PromptListLabel",
        "WaldoEcoCommand_PromptList",
        "WaldoEcoCommand_PromptPromote",
        "WaldoEcoCommand_PromptRemove",
        "WaldoEcoCommand_PromptClose"
    ]] call Waldo_fnc_EcoCore_deleteDisplayControlsByVars;

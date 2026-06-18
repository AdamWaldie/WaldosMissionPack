/*
 * Author: Waldo
 * Cleanup ground command prompt.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoCommand_cleanupGroundCommandPrompt;
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

/*
 * Author: WaldoTheWarfighter
 * Removes controls and closes the local Ground Command curator prompt.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - prompt display (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoCommand_cleanupGroundCommandPrompt;
 * Locality/Authority: Curator interface client only; does not change command authority.
 * Repeat/JIP Behaviour: Safe to call on a closed/null display; no JIP state is stored.
 * Current Callers: Ground Command prompt close button, unified save cleanup and Resource prompts.
 * Result: Removes the prompt controls from the supplied display.
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
    [_disp] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;

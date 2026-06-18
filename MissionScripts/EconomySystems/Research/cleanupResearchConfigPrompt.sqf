/*
 * Author: Waldo
 * Cleanup research config prompt.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoResearch_cleanupResearchConfigPrompt;
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        [_disp, "WaldoEcoResearch_InputTargets"] call Waldo_fnc_EcoCore_resetPromptInputTargets;
        [_disp, [
            "WaldoEcoResearch_ConfigBG",
            "WaldoEcoResearch_ConfigTitle",
            "WaldoEcoResearch_ConfigListLabel",
            "WaldoEcoResearch_ConfigList",
            "WaldoEcoResearch_ConfigNameLabel",
            "WaldoEcoResearch_ConfigNameEdit",
            "WaldoEcoResearch_ConfigDescLabel",
            "WaldoEcoResearch_ConfigDescEdit",
            "WaldoEcoResearch_ConfigCostsLabel",
            "WaldoEcoResearch_ConfigCostsEdit",
            "WaldoEcoResearch_ConfigReqsLabel",
            "WaldoEcoResearch_ConfigReqsEdit",
            "WaldoEcoResearch_ConfigExclusiveLabel",
            "WaldoEcoResearch_ConfigExclusiveEdit",
            "WaldoEcoResearch_ConfigTimeLabel",
            "WaldoEcoResearch_ConfigTimeEdit",
            "WaldoEcoResearch_ConfigColorLabel",
            "WaldoEcoResearch_ConfigColorEdit",
            "WaldoEcoResearch_ConfigResearchedCheck",
            "WaldoEcoResearch_ConfigResearchedLabel",
            "WaldoEcoResearch_ConfigIconLabel",
            "WaldoEcoResearch_ConfigIconPrev",
            "WaldoEcoResearch_ConfigIconValue",
            "WaldoEcoResearch_ConfigIconNext",
            "WaldoEcoResearch_ConfigAdd",
            "WaldoEcoResearch_ConfigRemove",
            "WaldoEcoResearch_ConfigSave",
            "WaldoEcoResearch_ConfigOk"
        ]] call Waldo_fnc_EcoCore_deleteDisplayControlsByVars;

        [_disp, [
            "WaldoEcoResearch_ConfigIconIndex",
            "WaldoEcoResearch_ConfigSelectedIndex"
        ]] call Waldo_fnc_EcoCore_clearDisplayVariables;
        [_disp] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;


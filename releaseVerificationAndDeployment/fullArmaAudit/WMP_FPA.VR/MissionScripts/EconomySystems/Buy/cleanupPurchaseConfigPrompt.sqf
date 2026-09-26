/*
 * Author: WaldoTheWarfighter
 * Removes controls from the curator purchase-catalog prompt and closes its display.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - prompt display (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoBuy_cleanupPurchaseConfigPrompt;
 * Locality/Authority: Curator interface client only; no catalog mutation.
 * Repeat/JIP Behaviour: Safe for a null/closed prompt; no JIP UI state.
 * Current Callers: Purchase-catalog prompt close/cancel and Economy UI cleanup.
 * Result: Temporary controls and prompt state are removed.
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        [_disp, "WaldoEcoBuy_InputTargets"] call Waldo_fnc_EcoCore_resetPromptInputTargets;
        [_disp, [
            "WaldoEcoBuy_ConfigBG",
            "WaldoEcoBuy_ConfigTitle",
            "WaldoEcoBuy_ConfigNameLabel",
            "WaldoEcoBuy_ConfigNameEdit",
            "WaldoEcoBuy_ConfigDescLabel",
            "WaldoEcoBuy_ConfigDescEdit",
            "WaldoEcoBuy_ConfigCostsLabel",
            "WaldoEcoBuy_ConfigCostsEdit",
            "WaldoEcoBuy_ConfigReqsLabel",
            "WaldoEcoBuy_ConfigReqsEdit",
            "WaldoEcoBuy_ConfigClassLabel",
            "WaldoEcoBuy_ConfigClassEdit",
            "WaldoEcoBuy_ConfigTypeLabel",
            "WaldoEcoBuy_ConfigTypePrev",
            "WaldoEcoBuy_ConfigTypeValue",
            "WaldoEcoBuy_ConfigTypeNext",
            "WaldoEcoBuy_ConfigSideLabel",
            "WaldoEcoBuy_ConfigSidePrev",
            "WaldoEcoBuy_ConfigSideValue",
            "WaldoEcoBuy_ConfigSideNext",
            "WaldoEcoBuy_ConfigIconLabel",
            "WaldoEcoBuy_ConfigIconPrev",
            "WaldoEcoBuy_ConfigIconValue",
            "WaldoEcoBuy_ConfigIconNext",
            "WaldoEcoBuy_ConfigColorLabel",
            "WaldoEcoBuy_ConfigColorEdit",
            "WaldoEcoBuy_ConfigListLabel",
            "WaldoEcoBuy_ConfigList",
            "WaldoEcoBuy_ConfigAdd",
            "WaldoEcoBuy_ConfigRemove",
            "WaldoEcoBuy_ConfigSave",
            "WaldoEcoBuy_ConfigOk"
        ]] call Waldo_fnc_EcoCore_deleteDisplayControlsByVars;
        [_disp] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;


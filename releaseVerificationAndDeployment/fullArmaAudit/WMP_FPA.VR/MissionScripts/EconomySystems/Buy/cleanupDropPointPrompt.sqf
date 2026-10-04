/*
 * Author: WaldoTheWarfighter
 * Removes controls from the curator delivery-point prompt and closes its display.
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
 * [_disp] call Waldo_fnc_EcoBuy_cleanupDropPointPrompt;
 * Locality/Authority: Curator interface client only; no registry mutation.
 * Repeat/JIP Behaviour: Safe for a null/closed prompt; no JIP UI state.
 * Current Callers: Delivery-point prompt close/cancel and Economy UI cleanup.
 * Result: Temporary controls and prompt state are removed.
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        [_disp, [
            "WaldoEcoBuy_DropBG",
            "WaldoEcoBuy_DropTitle",
            "WaldoEcoBuy_DropTypeLabel",
            "WaldoEcoBuy_DropTypePrev",
            "WaldoEcoBuy_DropTypeValue",
            "WaldoEcoBuy_DropTypeNext",
            "WaldoEcoBuy_DropSideLabel",
            "WaldoEcoBuy_DropSidePrev",
            "WaldoEcoBuy_DropSideValue",
            "WaldoEcoBuy_DropSideNext",
            "WaldoEcoBuy_DropCreate",
            "WaldoEcoBuy_DropCancel"
        ]] call Waldo_fnc_EcoCore_deleteDisplayControlsByVars;
        [_disp] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;


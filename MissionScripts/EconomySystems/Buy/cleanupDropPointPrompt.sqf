/*
 * Author: Waldo
 * Cleanup drop point prompt.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoBuy_cleanupDropPointPrompt;
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


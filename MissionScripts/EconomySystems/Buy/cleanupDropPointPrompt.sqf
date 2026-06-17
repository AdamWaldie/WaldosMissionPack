/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - cleanupDropPointPrompt
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_cleanupDropPointPrompt via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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


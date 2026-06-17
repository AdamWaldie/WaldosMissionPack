/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - cleanupPurchaseConfigPrompt
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_cleanupPurchaseConfigPrompt via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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


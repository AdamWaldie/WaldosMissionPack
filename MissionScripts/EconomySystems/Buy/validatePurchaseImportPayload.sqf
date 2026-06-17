/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - validatePurchaseImportPayload
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_validatePurchaseImportPayload via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_payload", []]];

        if !(_payload isEqualType []) exitWith {false};
        if ((count _payload) < 2) exitWith {false};
        if ((_payload param [0, ""]) isNotEqualTo "WaldoEcoBuy_PURCHASE_V1") exitWith {false};
        if !((_payload param [1, []]) isEqualType []) exitWith {false};

        true


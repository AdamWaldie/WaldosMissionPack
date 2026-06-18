/*
 * Author: Waldo
 * Validate purchase import payload.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _payload <ARRAY> - payload (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_payload] call Waldo_fnc_EcoBuy_validatePurchaseImportPayload;
 */

        params [["_payload", []]];

        if !(_payload isEqualType []) exitWith {false};
        if ((count _payload) < 2) exitWith {false};
        if ((_payload param [0, ""]) isNotEqualTo "WaldoEcoBuy_PURCHASE_V1") exitWith {false};
        if !((_payload param [1, []]) isEqualType []) exitWith {false};

        true


/*
 * Author: WaldoTheWarfighter
 * Checks the outer structure of a PURCHASE_V1 catalog import.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _payload <ARRAY> - payload (optional, default: [])
 *
 * Return Value:
 * <BOOL> true for a supported version with expected field types.
 *
 * Example:
 * [_payload] call Waldo_fnc_EcoBuy_validatePurchaseImportPayload;
 * Locality/Authority: Any machine; pure import structure validation.
 * Repeat/JIP Behaviour: Stateless; no JIP effect.
 * Current Callers: Economy Purchasing import handler.
 * Result: Malformed payloads are rejected before catalog replacement.
 */

        params [["_payload", []]];

        if !(_payload isEqualType []) exitWith {false};
        if ((count _payload) < 2) exitWith {false};
        if ((_payload param [0, ""]) isNotEqualTo "WaldoEcoBuy_PURCHASE_V1") exitWith {false};
        if !((_payload param [1, []]) isEqualType []) exitWith {false};

        true


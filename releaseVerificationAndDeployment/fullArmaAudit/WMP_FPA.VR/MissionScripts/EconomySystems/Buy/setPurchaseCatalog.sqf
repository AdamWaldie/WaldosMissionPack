/*
 * Author: WaldoTheWarfighter
 * Normalizes and broadcasts the authoritative purchasable-asset catalog.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _catalog <ARRAY> - catalog (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_catalog] call Waldo_fnc_EcoBuy_setPurchaseCatalog;
 * Locality/Authority: Economy authority only; clients receive the published catalog.
 * Repeat/JIP Behaviour: Repeated calls replace the catalog; JIP receives the latest value.
 * Current Callers: Purchasing ZEN configuration and exported mission setup calls.
 * Result: Only normalized asset rows become available for purchase.
 */

        params [["_catalog", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuy_PurchaseCatalog", [_catalog] call Waldo_fnc_EcoBuy_normalizePurchaseCatalog, true];


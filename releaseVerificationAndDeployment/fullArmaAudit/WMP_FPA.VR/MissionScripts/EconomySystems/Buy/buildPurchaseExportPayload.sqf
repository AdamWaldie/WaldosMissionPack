/*
 * Author: WaldoTheWarfighter
 * Serializes the purchase catalog in the supported PURCHASE_V1 format.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <STRING> serialized purchase payload.
 *
 * Example:
 * [] call Waldo_fnc_EcoBuy_buildPurchaseExportPayload;
 * Locality/Authority: Read-only export on the curator's machine.
 * Repeat/JIP Behaviour: Repeat calls serialize current published state without changing it.
 * Current Callers: Economy unified export and Purchasing authoring tools.
 * Result: Returns text suitable for later import validation.
 */

        private _catalog = call Waldo_fnc_EcoBuy_getPurchaseCatalog;
        str ["WaldoEcoBuy_PURCHASE_V1", _catalog]


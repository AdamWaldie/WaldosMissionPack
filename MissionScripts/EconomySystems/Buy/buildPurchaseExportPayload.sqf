/*
 * Author: Waldo
 * Build purchase export payload.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoBuy_buildPurchaseExportPayload;
 */

        private _catalog = call Waldo_fnc_EcoBuy_getPurchaseCatalog;
        str ["WaldoEcoBuy_PURCHASE_V1", _catalog]


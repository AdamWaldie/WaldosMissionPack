/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - buildPurchaseExportPayload
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_buildPurchaseExportPayload via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        private _catalog = call Waldo_fnc_EcoBuy_getPurchaseCatalog;
        str ["WaldoEcoBuy_PURCHASE_V1", _catalog]


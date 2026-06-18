/*
 * Author: Waldo
 * Get valid purchase catalog.
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
 * [] call Waldo_fnc_EcoBuy_getValidPurchaseCatalog;
 */

        private _catalog = call Waldo_fnc_EcoBuy_getPurchaseCatalog;
        _catalog select {!([_x, _catalog] call Waldo_fnc_EcoBuy_hasPurchaseEntryError)}


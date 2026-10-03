/*
 * Author: WaldoTheWarfighter
 * Filters invalid entries out of the currently published purchase catalog.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <ARRAY> usable catalog rows.
 *
 * Example:
 * [] call Waldo_fnc_EcoBuy_getValidPurchaseCatalog;
 * Locality/Authority: Any machine; read-only validation of published rows.
 * Repeat/JIP Behaviour: Repeat-safe; JIP uses the latest published catalog.
 * Current Callers: Purchase terminal display and selection logic.
 * Result: Stored rows are unchanged; invalid rows are excluded from the returned list.
 */

        private _catalog = call Waldo_fnc_EcoBuy_getPurchaseCatalog;
        _catalog select {!([_x, _catalog] call Waldo_fnc_EcoBuy_hasPurchaseEntryError)}


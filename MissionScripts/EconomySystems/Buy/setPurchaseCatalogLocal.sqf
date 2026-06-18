/*
 * Author: Waldo
 * Set purchase catalog local.
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
 * [_catalog] call Waldo_fnc_EcoBuy_setPurchaseCatalogLocal;
 */

        params [["_catalog", []]];
        missionNamespace setVariable ["WaldoEcoBuy_PurchaseCatalog", [_catalog] call Waldo_fnc_EcoBuy_normalizePurchaseCatalog];


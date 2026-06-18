/*
 * Author: Waldo
 * Purge purchase configuration.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_purgePurchaseConfiguration;
 */

    if (!isNil "Waldo_fnc_EcoBuy_setPurchaseCatalog") then {
        [[]] call Waldo_fnc_EcoBuy_setPurchaseCatalog;
    };

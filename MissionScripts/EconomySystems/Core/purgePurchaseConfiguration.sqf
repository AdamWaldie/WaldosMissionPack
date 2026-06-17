/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - purgePurchaseConfiguration
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_purgePurchaseConfiguration via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if (!isNil "Waldo_fnc_EcoBuy_setPurchaseCatalog") then {
        [[]] call Waldo_fnc_EcoBuy_setPurchaseCatalog;
    };

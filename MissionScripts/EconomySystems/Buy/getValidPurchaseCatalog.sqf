/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - getValidPurchaseCatalog
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_getValidPurchaseCatalog via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        private _catalog = call Waldo_fnc_EcoBuy_getPurchaseCatalog;
        _catalog select {!([_x, _catalog] call Waldo_fnc_EcoBuy_hasPurchaseEntryError)}


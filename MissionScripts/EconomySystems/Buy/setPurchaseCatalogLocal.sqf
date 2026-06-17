/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - setPurchaseCatalogLocal
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_setPurchaseCatalogLocal via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_catalog", []]];
        missionNamespace setVariable ["WaldoEcoBuy_PurchaseCatalog", [_catalog] call Waldo_fnc_EcoBuy_normalizePurchaseCatalog];


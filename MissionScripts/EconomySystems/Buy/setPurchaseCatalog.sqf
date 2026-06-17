/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - setPurchaseCatalog
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_setPurchaseCatalog via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_catalog", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuy_PurchaseCatalog", [_catalog] call Waldo_fnc_EcoBuy_normalizePurchaseCatalog, true];


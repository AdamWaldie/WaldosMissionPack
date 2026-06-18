/*
 * Author: Waldo
 * Set purchase catalog.
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
 * [_catalog] call Waldo_fnc_EcoBuy_setPurchaseCatalog;
 */

        params [["_catalog", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuy_PurchaseCatalog", [_catalog] call Waldo_fnc_EcoBuy_normalizePurchaseCatalog, true];


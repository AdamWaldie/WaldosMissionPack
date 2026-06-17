/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - importPurchaseConfiguration
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_importPurchaseConfiguration via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_payload", []]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if !([_payload] call Waldo_fnc_EcoBuy_validatePurchaseImportPayload) exitWith {};

        private _catalog = [];
        {
            private _entry = [_x] call Waldo_fnc_EcoBuy_normalizePurchaseEntry;
            if ((count _entry) <= 0) then {continue;};
            _catalog pushBack _entry;
        } forEach (_payload param [1, []]);

        [_catalog] call Waldo_fnc_EcoBuy_setPurchaseCatalog;


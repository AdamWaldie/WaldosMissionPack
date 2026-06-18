/*
 * Author: Waldo
 * Import purchase configuration.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _payload <ARRAY> - payload (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_payload] call Waldo_fnc_EcoBuy_importPurchaseConfiguration;
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


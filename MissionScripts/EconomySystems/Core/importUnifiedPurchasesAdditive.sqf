/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - importUnifiedPurchasesAdditive
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_importUnifiedPurchasesAdditive via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_payload", []]];

    if (isNil "Waldo_fnc_EcoCore_canRunAuthority" || {!([] call Waldo_fnc_EcoCore_canRunAuthority)}) exitWith {false};
    if (isNil "Waldo_fnc_EcoBuy_validatePurchaseImportPayload" || {isNil "Waldo_fnc_EcoBuy_normalizePurchaseEntry"} || {isNil "Waldo_fnc_EcoBuy_setPurchaseCatalog"} || {isNil "Waldo_fnc_EcoBuy_getPurchaseCatalog"}) exitWith {false};
    if !([_payload] call Waldo_fnc_EcoBuy_validatePurchaseImportPayload) exitWith {false};

    private _incomingCatalog = [];

    {
        private _entry = [_x] call Waldo_fnc_EcoBuy_normalizePurchaseEntry;
        if ((count _entry) <= 0) then {continue;};
        _incomingCatalog pushBack _entry;
    } forEach (_payload param [1, []]);

    private _mergedCatalog = [call Waldo_fnc_EcoBuy_getPurchaseCatalog, _incomingCatalog] call Waldo_fnc_EcoCore_mergeNamedEntryCatalogs;
    [_mergedCatalog] call Waldo_fnc_EcoBuy_setPurchaseCatalog;
    true

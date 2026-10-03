/*
 * Author: WaldoTheWarfighter
 * Stores a normalized purchase catalog locally before curator submission.
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
 * Locality/Authority: Local cache only; this is not the authoritative public setter.
 * Repeat/JIP Behaviour: Replaces local working rows; server snapshot supplies JIP state.
 * Current Callers: Purchase curator form edits before server submission.
 * Result: The local editor reads the normalized working catalog.
 */

        params [["_catalog", []]];
        missionNamespace setVariable ["WaldoEcoBuy_PurchaseCatalog", [_catalog] call Waldo_fnc_EcoBuy_normalizePurchaseCatalog];


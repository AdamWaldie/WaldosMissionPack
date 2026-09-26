/*
 * Author: WaldoTheWarfighter
 * Reads a copy of the currently published purchase catalog.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <ARRAY> asset rows, or [] before a catalog is configured.
 *
 * Example:
 * [] call Waldo_fnc_EcoBuy_getPurchaseCatalog;
 * Locality/Authority: Any machine; read-only public catalog lookup.
 * Repeat/JIP Behaviour: Repeat-safe read; JIP receives the current catalog.
 * Current Callers: Purchase validation, authoring and status helpers.
 * Result: Returns a copy so callers do not edit the stored catalog by reference.
 */

        +(missionNamespace getVariable ["WaldoEcoBuy_PurchaseCatalog", []])


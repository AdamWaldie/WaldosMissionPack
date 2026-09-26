/*
 * Author: WaldoTheWarfighter
 * Reads a copy of the current purchase delivery-point registry.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <ARRAY> registered drop-point rows, or [] when none exist.
 *
 * Example:
 * [] call Waldo_fnc_EcoBuy_getDropPoints;
 * Locality/Authority: Any machine; read-only public registry lookup.
 * Repeat/JIP Behaviour: Repeat-safe read; JIP receives the current rows.
 * Current Callers: Purchase delivery lookup, ZEN authoring and export helpers.
 * Result: Returns a copy of the stored registry.
 */

        +(missionNamespace getVariable ["WaldoEcoBuy_DropPoints", []])


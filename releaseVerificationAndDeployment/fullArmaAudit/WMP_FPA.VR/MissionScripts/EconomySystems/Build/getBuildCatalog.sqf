/*
 * Author: WaldoTheWarfighter
 * Reads a copy of the current Construction catalog.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <ARRAY> build definitions, or [] when none are configured.
 *
 * Example:
 * [] call Waldo_fnc_EcoBuild_getBuildCatalog;
 * Locality/Authority: Any machine; read-only published catalog lookup.
 * Repeat/JIP Behaviour: Repeat-safe read; JIP receives current public catalog.
 * Current Callers: Construction validation, status, authoring and export helpers.
 * Result: Returns a copy so callers cannot change stored rows by reference.
 */

        +(missionNamespace getVariable ["WaldoEcoBuild_BuildCatalog", []])


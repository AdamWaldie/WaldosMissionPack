/*
 * Author: WaldoTheWarfighter
 * Filters invalid Construction definitions out of the published catalog.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <ARRAY> usable build rows.
 *
 * Example:
 * [] call Waldo_fnc_EcoBuild_getValidBuildCatalog;
 * Locality/Authority: Any machine; read-only validation of published rows.
 * Repeat/JIP Behaviour: Repeat-safe; JIP sees current catalog.
 * Current Callers: Construction picker and status presentation.
 * Result: Stored rows are unchanged; invalid rows are excluded from the returned list.
 */

        private _catalog = call Waldo_fnc_EcoBuild_getBuildCatalog;
        _catalog select {
            !([_x, _catalog] call Waldo_fnc_EcoBuild_hasBuildEntryError)
        }


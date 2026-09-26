/*
 * Author: WaldoTheWarfighter
 * Filters invalid technology entries out of the current Research catalog.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <ARRAY> catalog rows that pass Research entry validation.
 *
 * Example:
 * [] call Waldo_fnc_EcoResearch_getValidResearchCatalog;
 * Locality/Authority: Any machine; reads the published catalog.
 * Repeat/JIP Behaviour: Repeat-safe read of current catalog state.
 * Current Callers: Research action/status presentation and catalog consumers.
 * Result: Returns only usable rows; the stored catalog is unchanged.
 */

        private _catalog = call Waldo_fnc_EcoResearch_getResearchCatalog;
        _catalog select { !([_x, _catalog] call Waldo_fnc_EcoResearch_hasResearchEntryError) }


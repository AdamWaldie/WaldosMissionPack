/*
 * Author: Waldo
 * Get valid research catalog.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoResearch_getValidResearchCatalog;
 */

        private _catalog = call Waldo_fnc_EcoResearch_getResearchCatalog;
        _catalog select { !([_x, _catalog] call Waldo_fnc_EcoResearch_hasResearchEntryError) }


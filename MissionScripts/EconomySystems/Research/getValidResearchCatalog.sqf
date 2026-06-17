/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - getValidResearchCatalog
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_getValidResearchCatalog via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        private _catalog = call Waldo_fnc_EcoResearch_getResearchCatalog;
        _catalog select { !([_x, _catalog] call Waldo_fnc_EcoResearch_hasResearchEntryError) }


/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - buildResearchExportPayload
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_buildResearchExportPayload via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_includeResearched", false]];

        private _catalog = call Waldo_fnc_EcoResearch_getResearchCatalog;
        private _payloadCatalog = [];

        {
            private _entry = +_x;
            if (!_includeResearched && {(count _entry) > 7}) then {
                _entry set [7, false];
            };
            _payloadCatalog pushBack _entry;
        } forEach _catalog;

        str ["WaldoEcoResearch_RESEARCH_V1", _includeResearched, _payloadCatalog]


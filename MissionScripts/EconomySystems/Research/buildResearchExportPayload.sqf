/*
 * Author: Waldo
 * Build research export payload.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _includeResearched <BOOL> - include researched (optional, default: false)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_includeResearched] call Waldo_fnc_EcoResearch_buildResearchExportPayload;
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


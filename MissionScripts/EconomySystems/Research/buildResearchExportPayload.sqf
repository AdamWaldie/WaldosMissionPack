/*
 * Author: WaldoTheWarfighter
 * Serializes the Research catalog for export, optionally including completion flags.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _includeResearched <BOOL> - include researched (optional, default: false)
 *
 * Return Value:
 * <STRING> serialized RESEARCH_V1 payload.
 *
 * Example:
 * [_includeResearched] call Waldo_fnc_EcoResearch_buildResearchExportPayload;
 * Locality/Authority: Read-only export on the machine opening the Economy authoring UI.
 * Repeat/JIP Behaviour: Repeat calls serialize current state; no network mutation or JIP work.
 * Current Callers: Economy unified export and Research authoring tools.
 * Result: Returns a text payload for later Research import.
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


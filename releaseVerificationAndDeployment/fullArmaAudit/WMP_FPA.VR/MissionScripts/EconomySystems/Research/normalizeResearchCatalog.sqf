/*
 * Author: WaldoTheWarfighter
 * Normalizes every technology row and removes unusable entries from a catalog.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _catalog <ARRAY> - catalog (optional, default: [])
 *
 * Return Value:
 * <ARRAY> normalized technology rows.
 *
 * Example:
 * [_catalog] call Waldo_fnc_EcoResearch_normalizeResearchCatalog;
 * Locality/Authority: Any machine; transforms supplied data without publishing it.
 * Repeat/JIP Behaviour: Deterministic for the same input; no JIP effect until the setter publishes.
 * Current Callers: EcoResearch_setResearchCatalog and Research import.
 * Result: Returns a safe catalog for the authoritative setter.
 */

        params [["_catalog", []]];

        private _result = [];

        {
            private _entry = [_x] call Waldo_fnc_EcoResearch_normalizeResearchEntry;
            if ((count _entry) <= 0) then {continue;};

            private _name = _entry param [0, ""];
            if ((_result findIf {(toLower (_x param [0, ""])) isEqualTo (toLower _name)}) >= 0) then {continue;};
            _result pushBack _entry;
        } forEach _catalog;

        _result


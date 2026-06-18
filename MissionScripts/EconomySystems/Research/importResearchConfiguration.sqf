/*
 * Author: Waldo
 * Import research configuration.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _payload <ANY> - payload
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_payload] call Waldo_fnc_EcoResearch_importResearchConfiguration;
 */

        params ["_payload"];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if !([_payload] call Waldo_fnc_EcoResearch_validateResearchImportPayload) exitWith {};

        private _includeResearched = _payload param [1, false];
        private _catalog = [];

        {
            private _entry = [_x] call Waldo_fnc_EcoResearch_normalizeResearchEntry;
            if ((count _entry) <= 0) then {continue;};
            if (!_includeResearched) then {
                _entry set [7, false];
            };
            _catalog pushBack _entry;
        } forEach (_payload param [2, []]);

        [_catalog] call Waldo_fnc_EcoResearch_setResearchCatalog;


/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - importUnifiedResearchAdditive
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_importUnifiedResearchAdditive via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_payload", []]];

    if (isNil "Waldo_fnc_EcoCore_canRunAuthority" || {!([] call Waldo_fnc_EcoCore_canRunAuthority)}) exitWith {false};
    if (isNil "Waldo_fnc_EcoResearch_validateResearchImportPayload" || {isNil "Waldo_fnc_EcoResearch_normalizeResearchEntry"} || {isNil "Waldo_fnc_EcoResearch_setResearchCatalog"} || {isNil "Waldo_fnc_EcoResearch_getResearchCatalog"}) exitWith {false};
    if !([_payload] call Waldo_fnc_EcoResearch_validateResearchImportPayload) exitWith {false};

    private _includeResearched = _payload param [1, false];
    private _incomingCatalog = [];

    {
        private _entry = [_x] call Waldo_fnc_EcoResearch_normalizeResearchEntry;
        if ((count _entry) <= 0) then {continue;};
        if (!_includeResearched) then {
            _entry set [7, false];
        };
        _incomingCatalog pushBack _entry;
    } forEach (_payload param [2, []]);

    private _mergedCatalog = [call Waldo_fnc_EcoResearch_getResearchCatalog, _incomingCatalog] call Waldo_fnc_EcoCore_mergeNamedEntryCatalogs;
    [_mergedCatalog] call Waldo_fnc_EcoResearch_setResearchCatalog;
    true

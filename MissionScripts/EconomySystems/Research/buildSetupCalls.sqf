/*
 * Author: WaldoTheWarfighter
 * Converts the economy state authored through Research Zeus modules into public setup calls.
 *
 * Arguments:
 * 0: include technology definitions
 * 1: include placed research centres
 *
 * Return Value:
 * ARRAY of STRING - ordered SQF statements.
 */
params [
    ["_includeDefinitions", true, [false]],
    ["_includePlacements", true, [false]]
];

private _lines = ["// RESEARCH MODULE SETUP"];

if (_includeDefinitions) then {
    _lines pushBack "// Research: Define Technology Tree";
    _lines pushBack (str [call Waldo_fnc_EcoResearch_getResearchCatalog] + " call Waldo_fnc_EcoResearch_setResearchCatalog;");
};

if (_includePlacements) then {
    _lines pushBack "";
    _lines pushBack "// Research: Place Research Centres";
    {
        _lines pushBack (str [getPosATL _x] + " call Waldo_fnc_EcoResearch_spawnResearchCenter;");
    } forEach ((allMissionObjects "Land_Research_HQ_F") select {
        _x getVariable ["WaldoEcoResearch_IsResearchCenter", false]
    });
};

_lines

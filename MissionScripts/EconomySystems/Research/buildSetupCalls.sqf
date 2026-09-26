/*
 * Author: WaldoTheWarfighter
 * Converts the economy state authored through Research Zeus modules into public setup calls.
 *
 * Arguments:
 * 0: include technology definitions <BOOL>, default true.
 * 1: include placed research centres <BOOL>, default true.
 *
 * Return Value:
 * ARRAY of STRING - ordered SQF statements.
 * Locality/Authority: Reads current Economy state on the machine building a curator export;
 * it does not apply any of the generated calls.
 * Repeat/JIP Behaviour: Read-only and repeat-safe. The exported statements should be placed
 * in authoritative mission setup before clients depend on them.
 * Current Callers: Economy unified export builder and Research authoring workflow.
 * Example: [true, true] call Waldo_fnc_EcoResearch_buildSetupCalls;
 * Result: Returns catalog setup followed by placement calls for registered research centres.
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

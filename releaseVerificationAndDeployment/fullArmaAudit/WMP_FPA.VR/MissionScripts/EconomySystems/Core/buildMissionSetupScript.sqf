/*
 * Author: WaldoTheWarfighter
 * Builds paste-ready MissionConfig\economyConfig.sqf setup from the current Zeus-authored economy.
 *
 * This is a one-shot authoring operation. It deliberately inspects the current tagged world
 * fixtures so a mission maker can configure and place an economy in Zeus, export it, and then
 * reproduce that setup from mission scripts on later runs.
 *
 * Arguments:
 * 0: include resources configuration
 * 1: include research configuration
 * 2: include buildings configuration
 * 3: include purchasing configuration
 * 4: include placed world fixtures
 *
 * Return Value:
 * STRING - SQF intended for MissionConfig\economyConfig.sqf.
 */
params [
    ["_includeResources", true, [false]],
    ["_includeResearch", true, [false]],
    ["_includeBuildings", true, [false]],
    ["_includeBuy", true, [false]],
    ["_includeFixtures", true, [false]]
];

private _newLine = toString [13, 10];
private _lines = [
    "/* WMP ECONOMY SETUP BUILT IN ZEUS",
    " * Paste this block into MissionConfig\economyConfig.sqf.",
    " * Set Waldo_Economy_Enable = true in init.sqf before using it.",
    " * Export from a clean authoring session before normal play begins.",
    " */",
    "if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};"
];

{
    _x params ["_enabled", "_builder"];
    if (_enabled && {!isNil _builder}) then {
        _lines pushBack "";
        _lines append ([true, _includeFixtures] call (missionNamespace getVariable [_builder, {}]));
    };
} forEach [
    [_includeResources, "Waldo_fnc_EcoResource_buildSetupCalls"],
    [_includeResearch, "Waldo_fnc_EcoResearch_buildSetupCalls"],
    [_includeBuildings, "Waldo_fnc_EcoBuild_buildSetupCalls"],
    [_includeBuy, "Waldo_fnc_EcoBuy_buildSetupCalls"]
];

if (missionNamespace getVariable ["Waldo_Economy_CommitmentMode", false]) then {
    _lines pushBack "";
    _lines pushBack "// Rules: Commitment Mode";
    _lines pushBack "missionNamespace setVariable [" + str "Waldo_Economy_CommitmentMode" + ", true, true];";
};

_lines joinString _newLine

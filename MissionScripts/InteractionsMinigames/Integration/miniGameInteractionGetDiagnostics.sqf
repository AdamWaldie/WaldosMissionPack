/*
 * Author: WaldoTheWarfighter
 * Returns normalized diagnostics for all ten procedure APIs and configured
 * interaction objects. Optional argument: objects to inspect.
 */
params [["_objects", [], [[]]]];
private _procedures = [
    ["wirecut", "Waldo_fnc_MiniGameWireCut"],
    ["minesweeper", "Waldo_fnc_MiniGameMinesweeper"],
    ["keypad", "Waldo_fnc_MiniGameKeypad"],
    ["lockpick", "Waldo_fnc_MiniGameLockpick"],
    ["circuit", "Waldo_fnc_MiniGameCircuit"],
    ["repair", "Waldo_fnc_MiniGameRepair"],
    ["radiotune", "Waldo_fnc_MiniGameRadioTune"],
    ["pressure", "Waldo_fnc_MiniGamePressure"],
    ["sequence", "Waldo_fnc_MiniGameSequence"],
    ["commandinput", "Waldo_fnc_MiniGameCommandInput"]
];
private _registry = missionNamespace getVariable ["Waldo_MG_ChallengeRegistry", []];
private _checks = [];
{
    _x params ["_id", "_function"];
    private _api = !(isNil _function);
    private _registered = (_registry findIf {(_x param [0, ""]) == _id}) >= 0;
    _checks pushBack ["interactions", format ["procedure-%1", _id], if (!_api) then {"ERROR"} else {if (_registered) then {"LOADED"} else {"UNCONFIGURED"}}, format ["function=%1 available=%2 locallyRegistered=%3", _function, _api, _registered]];
} forEach _procedures;

if (_objects isEqualTo [] && {hasInterface}) then {
    _objects = allMissionObjects "All" select {(_x getVariable ["Waldo_MG_Int_ChallengeId", ""]) != ""};
};
private _aceLoaded = isClass (configFile >> "CfgPatches" >> "ace_interact_menu");
private _invalidObjects = _objects select {
    private _challenge = _x getVariable ["Waldo_MG_Int_ChallengeId", ""];
    private _known = (_procedures findIf {(_x select 0) == _challenge}) >= 0;
    private _vanilla = !hasInterface || {_x getVariable ["Waldo_MG_Int_VanillaActionInstalled", false]};
    private _ace = !_aceLoaded || {!hasInterface} || {_x getVariable ["Waldo_MG_Int_ACEActionInstalled", false]};
    !_known || {!_vanilla} || {!_ace}
};
_checks pushBack ["interactions", "configured-equipment", if (!(_invalidObjects isEqualTo [])) then {"ERROR"} else {if (_objects isEqualTo []) then {"UNCONFIGURED"} else {if ((_objects findIf {(_x getVariable ["Waldo_MG_InteractionState", "IDLE"]) == "RUNNING"}) >= 0) then {"ACTIVE"} else {"LOADED"}}}, format ["objects=%1 invalid=%2 ACE=%3 vanillaRequired=%4", count _objects, count _invalidObjects, _aceLoaded, hasInterface]];

["interaction-procedures", _checks] call Waldo_fnc_DiagnosticFeatureReport

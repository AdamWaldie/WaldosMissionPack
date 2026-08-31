/*
 * Author: WaldoTheWarfighter
 * Reports interface-local availability and object setup for all ten field-equipment procedures.
 * This is read-only: it never opens a procedure or populates the lazy challenge UI registry merely
 * to make diagnostics look active. A procedure is LOADED when its function exists and either a
 * configured local object uses it or its opener has already been registered by normal use.
 *
 * Locality/authority and repeat/JIP behaviour: Runs on an interface client as part of the bounded
 * server diagnostic request. It inspects that client's local actions/registry and can be repeated;
 * it publishes no state and has no JIP side effects.
 *
 * Arguments:
 * 0: Objects to inspect <ARRAY<OBJECT>> (default []) - empty discovers locally configured objects.
 *
 * Return Value:
 * HashMap diagnostic feature report containing stable check identities and current local states.
 *
 * Current caller: Waldo_fnc_RunDiagnosticsClient.
 *
 * Example:
 * [] call Waldo_fnc_MiniGameInteractionGetDiagnostics;
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
if (_objects isEqualTo [] && {hasInterface}) then {
    _objects = allMissionObjects "All" select {(_x getVariable ["Waldo_MG_Int_ChallengeId", ""]) != ""};
};
private _registry = missionNamespace getVariable ["Waldo_MG_ChallengeRegistry", []];
private _configuredIds = _objects apply {_x getVariable ["Waldo_MG_Int_ChallengeId", ""]};
private _checks = [];
{
    _x params ["_id", "_function"];
    private _api = !(isNil _function);
    private _registered = (_registry findIf {(_x param [0, ""]) == _id}) >= 0;
    private _configuredCount = {_x == _id} count _configuredIds;
    private _availableForMission = _registered || {_configuredCount > 0};
    private _procDetail = format ["function=%1 available=%2 locallyRegistered=%3 configuredObjects=%4", _function, _api, _registered, _configuredCount];
    if !(_api) then {_procDetail = [_procDetail, format ["%1 is missing from this mission's copy of WMP - re-extract WaldosMissionPack\MissionScripts over this mission (or confirm WaldosFunctions.sqf wasn't edited) so it registers again.", _function]] call Waldo_fnc_DiagnosticFoldHint;};
    _checks pushBack ["interactions", format ["procedure-%1", _id], if (!_api) then {"ERROR"} else {if (_availableForMission) then {"LOADED"} else {"UNCONFIGURED"}}, _procDetail];
} forEach _procedures;

private _aceLoaded = isClass (configFile >> "CfgPatches" >> "ace_interact_menu");
private _invalidObjects = _objects select {
    private _challenge = _x getVariable ["Waldo_MG_Int_ChallengeId", ""];
    private _known = (_procedures findIf {(_x select 0) == _challenge}) >= 0;
    // installAction:false is a documented, intentional setup mode (Waldo_MG_Int_InteractionMode ==
    // "FEATURE_ACTION") for callers - the radio jammer's "Disable Jammer" action is the shipped
    // example - that install their own action and only use this framework for the challenge/state
    // machinery, deliberately without a second ACE/vanilla entry point for the same object. Neither
    // action is ever expected to install for those objects; flagging them as "invalid" was a false
    // positive that never reflected an actual failure to interact.
    private _featureOwned = (_x getVariable ["Waldo_MG_Int_InteractionMode", ""]) == "FEATURE_ACTION";
    private _vanilla = _featureOwned || {!hasInterface} || {_x getVariable ["Waldo_MG_Int_VanillaActionInstalled", false]};
    private _ace = _featureOwned || {!_aceLoaded} || {!hasInterface} || {_x getVariable ["Waldo_MG_Int_ACEActionInstalled", false]};
    !_known || {!_vanilla} || {!_ace}
};
private _equipmentDetail = format ["objects=%1 invalid=%2 ACE=%3 vanillaRequired=%4", count _objects, count _invalidObjects, _aceLoaded, hasInterface];
if !(_invalidObjects isEqualTo []) then {_equipmentDetail = [_equipmentDetail, "A configured object references an unknown challenge id, or is missing its expected ACE/vanilla action - check the RPT for errors from Waldo_fnc_MiniGameInteractionSetup on the affected object(s)."] call Waldo_fnc_DiagnosticFoldHint;};
_checks pushBack ["interactions", "configured-equipment", if (!(_invalidObjects isEqualTo [])) then {"ERROR"} else {if (_objects isEqualTo []) then {"UNCONFIGURED"} else {if ((_objects findIf {(_x getVariable ["Waldo_MG_InteractionState", "IDLE"]) == "RUNNING"}) >= 0) then {"ACTIVE"} else {"LOADED"}}}, _equipmentDetail];

["interaction-procedures", _checks] call Waldo_fnc_DiagnosticFeatureReport

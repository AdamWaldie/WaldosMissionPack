/*
 * Author: WaldoTheWarfighter
 * Loads one opt-in dialogue example pack into the server archetype catalogue.
 * Locality/authority: server only; clients never receive callback code or the full prose catalogue.
 * Repeat/JIP behaviour: repeat-safe replacement by archetype ID; action snapshots are unaffected.
 * Arguments: 0 pack ID <STRING>: MEDIEVAL_DORNOW or MODERN_CIVILIANS. Return Value: BOOL.
 * Current caller: mission-maker Eden init fields, triggers, scripts or server-authorised ZEN.
 * Example: ["MODERN_CIVILIANS"] call Waldo_fnc_DialogueLoadPresetPack;
 */
params [["_packId", "", [""]]];
if (!isServer) exitWith {false};
[] call Waldo_fnc_DialogueBootstrap;
private _path = switch (toUpperANSI _packId) do {
    case "MEDIEVAL_DORNOW": {"MissionScripts\MissionFlowAndUi\Dialogue\Presets\medievalDornow.sqf"};
    case "MODERN_CIVILIANS": {"MissionScripts\MissionFlowAndUi\Dialogue\Presets\modernCivilians.sqf"};
    default {""};
};
if (_path == "") exitWith {diag_log format ["[WMP DIALOGUE] Unknown preset pack '%1'.", _packId]; false};
private _pack = call compile preprocessFileLineNumbers _path;
if !(_pack isEqualType createHashMap) exitWith {diag_log format ["[WMP DIALOGUE] Preset pack '%1' is invalid.", _packId]; false};
private _catalogue = missionNamespace getVariable ["Waldo_Dialogue_Archetypes", createHashMap];
{_catalogue set [_x, +(_pack get _x)]} forEach keys _pack;
missionNamespace setVariable ["Waldo_Dialogue_Archetypes", _catalogue];
missionNamespace setVariable ["Waldo_Dialogue_PublicArchetypeIds", keys _catalogue, true];
diag_log format ["[WMP DIALOGUE] Loaded preset pack=%1 archetypes=%2.", toUpperANSI _packId, count keys _pack];
true

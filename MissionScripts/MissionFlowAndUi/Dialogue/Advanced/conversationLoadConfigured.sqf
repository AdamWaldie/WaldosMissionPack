/*
 * Author: WaldoTheWarfighter
 * Registers the code-free Advanced Conversation definitions loaded from dialogueConfig.sqf after
 * the authoritative SERVER configuration pass.
 * Locality/authority: server-only. Repeat/JIP behaviour: guarded one-time mission setup; individual
 * registrations remain replacement-safe and publish the current ID catalogue.
 * Arguments: None. Return Value: BOOL indicating that every configured row registered successfully.
 * Current caller: initServer.sqf immediately after LoadFeatureConfigs SERVER.
 * Example: [] call Waldo_fnc_ConversationLoadConfigured;
 */
if (!isServer) exitWith {false};
if (missionNamespace getVariable ["Waldo_Conversation_ConfigLoaded", false]) exitWith {true};
[] call Waldo_fnc_DialogueBootstrap;
private _definitions = missionNamespace getVariable ["Waldo_Conversation_ConfigDefinitions", []];
private _valid = _definitions isEqualType [];
if (_valid) then {
    {if !([_x] call Waldo_fnc_ConversationCreateData) then {_valid = false}} forEach _definitions;
} else {
    diag_log "[WMP CONVERSATION] Waldo_Conversation_ConfigDefinitions must be an ARRAY.";
};
missionNamespace setVariable ["Waldo_Conversation_ConfigLoaded", true];
diag_log format ["[WMP CONVERSATION] Configured definitions loaded=%1 valid=%2.", if (_definitions isEqualType []) then {count _definitions} else {-1}, _valid];
_valid

/*
 * Author: WaldoTheWarfighter
 * Authenticates an interaction request, locks the NPC, and starts the registered dialogue engine.
 * Locality/authority: remote server endpoint; the claimed caller must be owned by remoteExecutedOwner.
 * Repeat/JIP behaviour: one active session per speaker; competing requests receive an occupied
 * notice. Every rejected request is counted by reason and written to the server RPT.
 * Arguments: 0 speaker <OBJECT>; 1 caller <OBJECT>. Return Value: BOOL.
 * Current caller: local ACE/vanilla dialogue actions. Example: [npc,player] remoteExecCall ["Waldo_fnc_DialogueRequestStartServer",2];
 */
params [["_speaker", objNull, [objNull]], ["_caller", objNull, [objNull]]];
private _reject = {
    params ["_reason", ["_detail", "", [""]]];
    private _counts = missionNamespace getVariable ["Waldo_Dialogue_RejectedRequestCounts", createHashMap];
    _counts set [_reason, (_counts getOrDefault [_reason, 0]) + 1];
    missionNamespace setVariable ["Waldo_Dialogue_RejectedRequestCounts", _counts];
    diag_log format ["[WMP DIALOGUE] Start rejected reason=%1 detail=%2 speaker=%3 caller=%4 remoteOwner=%5 counts=%6.", _reason, _detail, _speaker, _caller, remoteExecutedOwner, _counts];
    false
};
if (!isServer) exitWith {["WRONG_AUTHORITY"] call _reject};
if (isNull _speaker || {isNull _caller}) exitWith {["INVALID_ENTITY"] call _reject};
if (isRemoteExecuted && {owner _caller != remoteExecutedOwner}) exitWith {["OWNER_MISMATCH", format ["callerOwner=%1", owner _caller]] call _reject};
private _interactionDistance = missionNamespace getVariable ["Waldo_Dialogue_InteractionDistance", 3];
if (!alive _speaker || {!alive _caller}) exitWith {["NOT_ALIVE"] call _reject};
if (_caller distance _speaker > _interactionDistance) exitWith {["OUT_OF_RANGE", format ["distance=%1 maximum=%2", _caller distance _speaker, _interactionDistance]] call _reject};
private _key = netId _speaker; if (_key == "0:0") then {_key = str _speaker};
private _registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", createHashMap];
private _entry = _registry getOrDefault [_key, createHashMap];
if (count _entry == 0 || {!(_speaker getVariable ["Waldo_Dialogue_Available", false])}) exitWith {["NOT_REGISTERED_OR_UNAVAILABLE", _key] call _reject};
if ((_entry getOrDefault ["activeSession", ""]) != "") exitWith {
    ["BUSY", _entry getOrDefault ["activeSession", ""]] call _reject;
    ["DIALOGUE", format ["%1 is speaking with someone else.", name _speaker], "INFO", "DIALOGUE_BUSY", 4] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _caller];
    false
};
private _sessionId = ["DIALOGUE"] call Waldo_fnc_CreateRuntimeId;
_entry set ["activeSession", _sessionId];
_entry set ["activeCaller", _caller];
_entry set ["cancelRequested", ""];
_entry set ["offeredChoiceIds", []];
_entry set ["selectedChoice", ""];
_registry set [_key, _entry];
missionNamespace setVariable ["Waldo_Dialogue_Registry", _registry];
_speaker setVariable ["Waldo_Dialogue_Occupied", true, true];
private _kind = _entry getOrDefault ["kind", "SIMPLE"];
if (_kind == "ADVANCED") then {
    [_key, _sessionId] spawn Waldo_fnc_ConversationRunServer;
} else {
    [_key, _sessionId] spawn Waldo_fnc_DialogueRunSimpleServer;
};
true

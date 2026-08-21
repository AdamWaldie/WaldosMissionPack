/*
 * Author: WaldoTheWarfighter
 * Requests cancellation of the active Advanced Conversation for one speaker.
 * Locality/authority: server endpoint; remote callers must own the supplied player.
 * Repeat/JIP behaviour: token-aware and idempotent. Arguments: speaker OBJECT, caller OBJECT,
 * optional session ID STRING and reason STRING. Return Value: BOOL.
 * Current callers: response-panel cancel/unload, scripts and ZEN. Example: [npc,player] remoteExecCall ["Waldo_fnc_ConversationCancel",2];
 */
params [["_speaker", objNull, [objNull]], ["_caller", objNull, [objNull]], ["_sessionId", "", [""]], ["_reason", "CANCELLED", [""]]];
if (!isServer || {isNull _speaker}) exitWith {false};
if (isRemoteExecuted && {isNull _caller || {owner _caller != remoteExecutedOwner}}) exitWith {false};
private _key = netId _speaker; if (_key == "0:0") then {_key = str _speaker};
private _registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", createHashMap];
private _entry = _registry getOrDefault [_key, createHashMap];
private _active = _entry getOrDefault ["activeSession", ""];
if (_active == "" || {_sessionId != "" && {_sessionId != _active}}) exitWith {false};
if (isRemoteExecuted && {_entry getOrDefault ["activeCaller", objNull] != _caller}) exitWith {false};
_entry set ["cancelRequested", _reason];
_registry set [_key, _entry];
missionNamespace setVariable ["Waldo_Dialogue_Registry", _registry];
true

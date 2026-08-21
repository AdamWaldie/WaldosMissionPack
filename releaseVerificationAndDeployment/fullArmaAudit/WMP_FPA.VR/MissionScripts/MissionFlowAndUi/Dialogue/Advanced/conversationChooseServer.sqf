/*
 * Author: WaldoTheWarfighter
 * Accepts one offered response choice from the player who owns the active conversation session.
 * Locality/authority: authenticated remote server endpoint; clients submit IDs only.
 * Repeat/JIP behaviour: first valid selection wins and later duplicates are rejected.
 * Arguments: speaker, caller, session ID, choice ID. Return Value: BOOL.
 * Current caller: Advanced response panel. Example: internal UI remote execution only.
 */
params [["_speaker", objNull, [objNull]], ["_caller", objNull, [objNull]], ["_sessionId", "", [""]], ["_choiceId", "", [""]]];
if (!isServer || {isNull _speaker} || {isNull _caller} || {_choiceId == ""}) exitWith {false};
if (isRemoteExecuted && {owner _caller != remoteExecutedOwner}) exitWith {false};
private _key = netId _speaker; if (_key == "0:0") then {_key = str _speaker};
private _registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", createHashMap];
private _entry = _registry getOrDefault [_key, createHashMap];
if (_entry getOrDefault ["activeSession", ""] != _sessionId || {_entry getOrDefault ["activeCaller", objNull] != _caller}) exitWith {false};
if ((_entry getOrDefault ["selectedChoice", ""]) != "") exitWith {false};
private _offered = _entry getOrDefault ["offeredChoiceIds", []];
if !(_choiceId in _offered) exitWith {false};
_entry set ["selectedChoice", _choiceId];
_registry set [_key, _entry];
missionNamespace setVariable ["Waldo_Dialogue_Registry", _registry];
true

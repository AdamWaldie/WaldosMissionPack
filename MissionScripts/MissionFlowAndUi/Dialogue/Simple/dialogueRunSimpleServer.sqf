/*
 * Author: WaldoTheWarfighter
 * Runs one authoritative Simple Dialogue session, dynamically selecting nearby recipients and
 * executing the stored completion callback exactly once after genuine completion.
 * Locality/authority: scheduled server worker; animation is remoted to the current speaker owner.
 * Repeat/JIP behaviour: session token prevents stale workers from releasing a newer lock.
 * Arguments: 0 registry key <STRING>; 1 session ID <STRING>. Return Value: BOOL.
 * Current caller: DialogueRequestStartServer. Example: internal server worker only.
 */
params [["_key", "", [""]], ["_sessionId", "", [""]]];
if (!isServer) exitWith {false};
private _registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", createHashMap];
private _entry = _registry getOrDefault [_key, createHashMap];
if (count _entry == 0 || {_entry getOrDefault ["activeSession", ""] != _sessionId}) exitWith {false};
private _speaker = _entry getOrDefault ["speaker", objNull];
private _caller = _entry getOrDefault ["activeCaller", objNull];
private _lines = +(_entry getOrDefault ["lines", []]);
private _archetype = _entry getOrDefault ["archetype", "SPECIFIC"];
if (_archetype != "SPECIFIC") then {
    private _catalogue = missionNamespace getVariable ["Waldo_Dialogue_Archetypes", createHashMap];
    private _pool = _catalogue getOrDefault [_archetype, []];
    _lines = if (count _pool > 0) then {[selectRandom _pool]} else {[]};
};
private _completed = count _lines > 0;
private _cancelReason = "";
[ _speaker, _caller, true, "" ] remoteExecCall ["Waldo_fnc_DialogueAnimateLocal", 0];
{
    if (!_completed) exitWith {};
    if (isNull _speaker || {isNull _caller} || {!alive _speaker} || {!alive _caller} || {isMultiplayer && {!isPlayer _caller}}) then {_completed = false; _cancelReason = "ENTITY_INVALID"} else {
        if (_speaker distance _caller > (missionNamespace getVariable ["Waldo_Dialogue_CancelDistance", 6])) then {_completed = false; _cancelReason = "OUT_OF_RANGE"};
    };
    if (!_completed) exitWith {};
    private _duration = [_x] call Waldo_fnc_DialogueEstimateDuration;
    private _token = format ["%1_%2", _sessionId, _forEachIndex];
    private _recipients = allPlayers select {!(_x isKindOf "HeadlessClient_F") && {_x distance _speaker <= (missionNamespace getVariable ["Waldo_Dialogue_AudienceRadius", 10])}};
    [name _speaker, _x, _duration, _token] remoteExecCall ["Waldo_fnc_DialogueShowLineLocal", _recipients];
    private _deadline = diag_tickTime + _duration;
    waitUntil {
        uiSleep 0.1;
        isNull _speaker || {isNull _caller} || {!alive _speaker} || {!alive _caller} || {isMultiplayer && {!isPlayer _caller}}
        || {_speaker distance _caller > (missionNamespace getVariable ["Waldo_Dialogue_CancelDistance", 6])}
        || {diag_tickTime >= _deadline}
    };
    if (isNull _speaker || {isNull _caller} || {!alive _speaker} || {!alive _caller} || {isMultiplayer && {!isPlayer _caller}}) then {_completed = false; _cancelReason = "ENTITY_INVALID"};
    if (_completed && {_speaker distance _caller > (missionNamespace getVariable ["Waldo_Dialogue_CancelDistance", 6])}) then {_completed = false; _cancelReason = "OUT_OF_RANGE"};
} forEach _lines;
if (!isNull _speaker) then {[_speaker, _caller, false, ""] remoteExecCall ["Waldo_fnc_DialogueAnimateLocal", 0]};
if (!isNull _caller) then {[_sessionId] remoteExecCall ["Waldo_fnc_DialogueHideLocal", owner _caller]};

_registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", createHashMap];
_entry = _registry getOrDefault [_key, createHashMap];
if (count _entry == 0 || {_entry getOrDefault ["activeSession", ""] != _sessionId}) exitWith {false};
if (_completed) then {
    private _callback = _entry getOrDefault ["onComplete", {}];
    if !(_callback isEqualTo {}) then {
        [_speaker, _caller, createHashMapFromArray [["kind", "SIMPLE"], ["sessionId", _sessionId], ["reason", "COMPLETED"]]] call _callback;
    };
};
private _remove = _completed && {_entry getOrDefault ["removeAfterUse", false]};
if (_remove) then {
    _registry deleteAt _key;
    if (!isNull _speaker) then {_speaker setVariable ["Waldo_Dialogue_Available", false, true]};
} else {
    _entry set ["activeSession", ""];
    _entry set ["activeCaller", objNull];
    _registry set [_key, _entry];
};
if (!isNull _speaker) then {_speaker setVariable ["Waldo_Dialogue_Occupied", false, true]};
missionNamespace setVariable ["Waldo_Dialogue_Registry", _registry];
if (_remove) then {[] call Waldo_fnc_DialoguePublishState};
diag_log format ["[WMP DIALOGUE] Session=%1 completed=%2 cancelReason=%3 remove=%4.", _sessionId, _completed, _cancelReason, _remove];
_completed

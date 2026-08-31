/*
 * Author: WaldoTheWarfighter
 * Runs one server-authoritative linear or branching Advanced Conversation session.
 * Locality/authority: scheduled server worker; clients receive text/audio/choice descriptors only.
 * Repeat/JIP behaviour: session token, 256-transition cap and explicit cleanup prevent stale workers.
 * Arguments: registry key STRING, session ID STRING. Return Value: BOOL.
 * Current caller: DialogueRequestStartServer. Example: internal server worker only.
 */
params [["_key", "", [""]], ["_sessionId", "", [""]]];
if (!isServer) exitWith {false};
private _registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", createHashMap];
private _entry = _registry getOrDefault [_key, createHashMap];
if (count _entry == 0 || {_entry getOrDefault ["activeSession", ""] != _sessionId}) exitWith {false};
private _rootSpeaker = _entry getOrDefault ["speaker", objNull];
private _caller = _entry getOrDefault ["activeCaller", objNull];
private _conversationId = _entry getOrDefault ["conversationId", ""];
private _definitions = missionNamespace getVariable ["Waldo_Conversation_Definitions", createHashMap];
private _definition = _definitions getOrDefault [_conversationId, createHashMap];
private _nodes = _definition getOrDefault ["nodes", createHashMap];
private _nodeId = _definition getOrDefault ["startNode", ""];
private _transition = 0;
private _completed = count _definition > 0;
private _reason = if (_completed) then {"COMPLETED"} else {"DEFINITION_MISSING"};
private _lastChoice = "";

while {_completed && {_nodeId != ""} && {_transition < 256}} do {
    _transition = _transition + 1;
    _registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", createHashMap];
    _entry = _registry getOrDefault [_key, createHashMap];
    if (count _entry == 0 || {_entry getOrDefault ["activeSession", ""] != _sessionId}) then {_completed = false; _reason = "SESSION_REPLACED"} else {
        private _requested = _entry getOrDefault ["cancelRequested", ""];
        if (_requested != "") then {_completed = false; _reason = _requested};
    };
    if (!_completed) then {continue};
    if (isNull _rootSpeaker || {isNull _caller} || {!alive _rootSpeaker} || {!alive _caller} || {isMultiplayer && {!isPlayer _caller}} || {_rootSpeaker distance _caller > (missionNamespace getVariable ["Waldo_Dialogue_CancelDistance", 6])}) then {_completed = false; _reason = "ENTITY_OR_RANGE"; continue};
    private _node = _nodes getOrDefault [_nodeId, createHashMap];
    if (count _node == 0) then {_completed = false; _reason = "NODE_MISSING"; continue};
    private _context = createHashMapFromArray [["kind", "ADVANCED"], ["conversationId", _conversationId], ["sessionId", _sessionId], ["nodeId", _nodeId], ["choiceId", _lastChoice], ["reason", "RUNNING"]];
    private _onEnter = _node getOrDefault ["onEnter", {}];
    if !(_onEnter isEqualTo {}) then {[_rootSpeaker, _caller, _context] call _onEnter};
    {
        if (!_completed) exitWith {};
        private _line = _x;
        private _lineSpeaker = _line getOrDefault ["speaker", objNull];
        if (isNull _lineSpeaker) then {_lineSpeaker = _rootSpeaker};
        private _text = _line getOrDefault ["text", ""];
        private _sound = _line getOrDefault ["sound", ""];
        private _soundDuration = _line getOrDefault ["soundDuration", -1];
        private _override = _line getOrDefault ["duration", -1];
        private _validSound = _sound != "" && {isClass (missionConfigFile >> "CfgSounds" >> _sound)};
        private _duration = if (_validSound && {_soundDuration > 0}) then {_soundDuration} else {[_text, _override] call Waldo_fnc_DialogueEstimateDuration};
        private _recipients = allPlayers select {!(_x isKindOf "HeadlessClient_F") && {_x distance _lineSpeaker <= (missionNamespace getVariable ["Waldo_Dialogue_AudienceRadius", 10])}};
        private _lineToken = format ["%1_%2_%3", _sessionId, _transition, _forEachIndex];
        [name _lineSpeaker, _text, _duration, _lineToken] remoteExecCall ["Waldo_fnc_DialogueShowLineLocal", _recipients];
        if (_validSound) then {[_lineSpeaker, _sound] remoteExecCall ["Waldo_fnc_ConversationPlaySoundLocal", _recipients]} else {
            if (_sound != "") then {diag_log format ["[WMP CONVERSATION] Missing CfgSounds id '%1'; calculated text timing used.", _sound]};
        };
        [_lineSpeaker, _caller, true, _line getOrDefault ["gesture", ""]] remoteExecCall ["Waldo_fnc_DialogueAnimateLocal", 0];
        private _deadline = diag_tickTime + (_duration max 0.1);
        waitUntil {
            uiSleep 0.1;
            _registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", createHashMap];
            _entry = _registry getOrDefault [_key, createHashMap];
            isNull _rootSpeaker || {isNull _caller} || {!alive _rootSpeaker} || {!alive _caller} || {isMultiplayer && {!isPlayer _caller}}
            || {_rootSpeaker distance _caller > (missionNamespace getVariable ["Waldo_Dialogue_CancelDistance", 6])}
            || {_entry getOrDefault ["cancelRequested", ""] != ""} || {diag_tickTime >= _deadline}
        };
        [_lineSpeaker, _caller, false, ""] remoteExecCall ["Waldo_fnc_DialogueAnimateLocal", 0];
        private _requested = _entry getOrDefault ["cancelRequested", ""];
        if (_requested != "") then {_completed = false; _reason = _requested};
        if (_completed && {isNull _rootSpeaker || {isNull _caller} || {!alive _rootSpeaker} || {!alive _caller} || {isMultiplayer && {!isPlayer _caller}} || {_rootSpeaker distance _caller > (missionNamespace getVariable ["Waldo_Dialogue_CancelDistance", 6])}}) then {_completed = false; _reason = "ENTITY_OR_RANGE"};
    } forEach (_node getOrDefault ["lines", []]);
    if (!_completed) then {continue};
    private _nodeChoices = _node getOrDefault ["choices", []];
    private _availableChoices = [];
    private _choiceDescriptors = [];
    {
        private _condition = _x getOrDefault ["condition", {true}];
        private _enabled = [_rootSpeaker, _caller, _context] call _condition;
        if (_enabled) then {_availableChoices pushBack _x};
        private _destinationId = toUpperANSI (_x getOrDefault ["next", ""]);
        private _destination = _nodes getOrDefault [_destinationId, createHashMap];
        private _branchesToChoices = _destinationId != "" && {count (_destination getOrDefault ["choices", []]) > 0};
        _choiceDescriptors pushBack [_x getOrDefault ["id", ""], _x getOrDefault ["label", "Response"], _enabled, _branchesToChoices];
    } forEach _nodeChoices;
    if (count _availableChoices == 0) then {
        _nodeId = toUpperANSI (_node getOrDefault ["next", ""]);
    } else {
        _registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", createHashMap];
        _entry = _registry get _key;
        _entry set ["offeredChoiceIds", _choiceDescriptors apply {_x select 0}];
        _entry set ["selectedChoice", ""];
        _registry set [_key, _entry]; missionNamespace setVariable ["Waldo_Dialogue_Registry", _registry];
        [_rootSpeaker, _sessionId, _choiceDescriptors] remoteExecCall ["Waldo_fnc_ConversationShowChoicesLocal", owner _caller];
        waitUntil {
            uiSleep 0.1;
            _registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", createHashMap];
            _entry = _registry getOrDefault [_key, createHashMap];
            (_entry getOrDefault ["selectedChoice", ""]) != "" || {(_entry getOrDefault ["cancelRequested", ""]) != ""}
            || {count _entry == 0} || {_entry getOrDefault ["activeSession", ""] != _sessionId}
            || {isNull _caller} || {isNull _rootSpeaker} || {!alive _caller} || {!alive _rootSpeaker}
            || {lifeState _caller in ["INCAPACITATED", "DEAD"]} || {lifeState _rootSpeaker in ["INCAPACITATED", "DEAD"]}
            || {isMultiplayer && {!isPlayer _caller}} || {_rootSpeaker distance _caller > (missionNamespace getVariable ["Waldo_Dialogue_CancelDistance", 6])}
        };
        [_sessionId] remoteExecCall ["Waldo_fnc_ConversationHideChoicesLocal", owner _caller];
        private _requested = _entry getOrDefault ["cancelRequested", ""];
        if (_requested != "") then {_completed = false; _reason = _requested} else {
            _lastChoice = _entry getOrDefault ["selectedChoice", ""];
            private _choiceIndex = _availableChoices findIf {_x getOrDefault ["id", ""] == _lastChoice};
            if (_choiceIndex < 0) then {_completed = false; _reason = "CHOICE_INVALID"} else {
                private _choice = _availableChoices select _choiceIndex;
                _context set ["choiceId", _lastChoice];
                private _onSelect = _choice getOrDefault ["onSelect", {}];
                if !(_onSelect isEqualTo {}) then {[_rootSpeaker, _caller, _context] call _onSelect};
                _nodeId = toUpperANSI (_choice getOrDefault ["next", ""]);
            };
        };
    };
};
if (_transition >= 256 && {_nodeId != ""}) then {_completed = false; _reason = "TRANSITION_LIMIT"};
if (!isNull _caller) then {[_sessionId] remoteExecCall ["Waldo_fnc_ConversationHideChoicesLocal", owner _caller]; [_sessionId] remoteExecCall ["Waldo_fnc_DialogueHideLocal", owner _caller]};
private _finalContext = createHashMapFromArray [["kind", "ADVANCED"], ["conversationId", _conversationId], ["sessionId", _sessionId], ["nodeId", _nodeId], ["choiceId", _lastChoice], ["reason", _reason]];
private _hook = if (_completed) then {_definition getOrDefault ["onComplete", {}]} else {_definition getOrDefault ["onCancel", {}]};
if !(_hook isEqualTo {}) then {[_rootSpeaker, _caller, _finalContext] call _hook};
_registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", createHashMap];
_entry = _registry getOrDefault [_key, createHashMap];
if (count _entry > 0 && {_entry getOrDefault ["activeSession", ""] == _sessionId}) then {
    private _remove = _completed && {_entry getOrDefault ["removeAfterUse", false]};
    if (_remove) then {_registry deleteAt _key; _rootSpeaker setVariable ["Waldo_Dialogue_Available", false, true]} else {_entry set ["activeSession", ""]; _entry set ["activeCaller", objNull]; _entry set ["cancelRequested", ""]; _entry set ["offeredChoiceIds", []]; _entry set ["selectedChoice", ""]; _registry set [_key, _entry]};
    _rootSpeaker setVariable ["Waldo_Dialogue_Occupied", false, true];
    missionNamespace setVariable ["Waldo_Dialogue_Registry", _registry];
    if (_remove) then {[] call Waldo_fnc_DialoguePublishState};
};
diag_log format ["[WMP CONVERSATION] id=%1 session=%2 completed=%3 reason=%4 transitions=%5.", _conversationId, _sessionId, _completed, _reason, _transition];
_completed

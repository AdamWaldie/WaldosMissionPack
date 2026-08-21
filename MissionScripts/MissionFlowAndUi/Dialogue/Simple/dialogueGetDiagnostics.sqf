/*
 * Author: WaldoTheWarfighter
 * Reports authoritative Dialogue registry integrity on the server and ordered snapshot, action,
 * presentation and UI-cleanup integrity on each interface client.
 * Locality/authority: read-only on any machine; server checks authoritative mutable state while
 * interface clients check only their local JIP snapshot and presentation state.
 * Repeat/JIP behaviour: side-effect-free and safe to call repeatedly before, during or after a
 * conversation. A client without its ordered snapshot reports ERROR rather than guessing state.
 * Arguments: None.
 * Return Value: HASHMAP in the shared Waldo diagnostic feature-report schema.
 * Current callers: RunDiagnostics and RunDiagnosticsClient.
 * Example: call Waldo_fnc_DialogueGetDiagnostics;
 */
private _checks = [];
if (isServer) then {
    private _registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", nil];
    private _definitions = missionNamespace getVariable ["Waldo_Conversation_Definitions", nil];
    private _registryValid = !isNil "_registry" && {_registry isEqualType createHashMap};
    private _definitionsValid = !isNil "_definitions" && {_definitions isEqualType createHashMap};
    private _invalidEntries = [];
    private _presentationLocalityProblems = [];
    private _activeCount = 0;
    private _remotePresentationCount = 0;
    if (_registryValid) then {
        {
            private _key = _x;
            private _entry = _registry get _key;
            private _entryValid = _entry isEqualType createHashMap;
            private _speaker = if (_entryValid) then {_entry getOrDefault ["speaker", objNull]} else {objNull};
            private _kind = if (_entryValid) then {_entry getOrDefault ["kind", ""]} else {""};
            private _session = if (_entryValid) then {_entry getOrDefault ["activeSession", ""]} else {""};
            private _caller = if (_entryValid) then {_entry getOrDefault ["activeCaller", objNull]} else {objNull};
            private _referenceValid = _kind == "SIMPLE"
                || {_kind == "ADVANCED" && {_definitionsValid} && {(_entry getOrDefault ["conversationId", ""]) in keys _definitions}};
            private _lockValid = if (_session == "") then {
                isNull _caller && {isNull _speaker || {!(_speaker getVariable ["Waldo_Dialogue_Occupied", false])}}
            } else {
                _activeCount = _activeCount + 1;
                if (local _speaker) then {
                    private _lookTargetNetId = _speaker getVariable ["Waldo_Dialogue_LookTargetNetId", ""];
                    private _presentationOwner = _speaker getVariable ["Waldo_Dialogue_PresentationOwner", -1];
                    if (_lookTargetNetId != netId _caller || {_presentationOwner != owner _speaker}) then {
                        _presentationLocalityProblems pushBack [_key, owner _speaker, _presentationOwner, _lookTargetNetId, netId _caller];
                    };
                } else {
                    _remotePresentationCount = _remotePresentationCount + 1;
                };
                !isNull _caller && {!isNull _speaker} && {_speaker getVariable ["Waldo_Dialogue_Occupied", false]}
            };
            if !(_entryValid && {!isNull _speaker} && {_kind in ["SIMPLE", "ADVANCED"]} && {_referenceValid} && {_lockValid}) then {
                _invalidEntries pushBack _key;
            };
        } forEach keys _registry;
    };
    _checks pushBack ["dialogue", "server-registry", if (!_registryValid || {count _invalidEntries > 0}) then {"ERROR"} else {if (count _registry > 0) then {"ACTIVE"} else {"LOADED"}}, format ["registered=%1 active=%2 invalid=%3", if (_registryValid) then {count _registry} else {-1}, _activeCount, _invalidEntries]];
    _checks pushBack ["dialogue", "advanced-definitions", if (_definitionsValid) then {if (count _definitions > 0) then {"ACTIVE"} else {"UNCONFIGURED"}} else {"ERROR"}, format ["definitions=%1", if (_definitionsValid) then {count _definitions} else {-1}]];
    _checks pushBack ["dialogue", "presentation-locality", if (count _presentationLocalityProblems == 0) then {"LOADED"} else {"ERROR"}, format ["active=%1 remoteOwned=%2 localMismatches=%3", _activeCount, _remotePresentationCount, _presentationLocalityProblems]];
    private _rejectedRequests = missionNamespace getVariable ["Waldo_Dialogue_RejectedRequestCounts", createHashMap];
    _checks pushBack ["dialogue", "request-rejections", if (count _rejectedRequests > 0) then {"ACTIVE"} else {"LOADED"}, format ["counts=%1", _rejectedRequests]];
    private _subtitleMin = missionNamespace getVariable ["Waldo_Dialogue_SubtitleMinimumWidth", 0.22];
    private _subtitleMax = missionNamespace getVariable ["Waldo_Dialogue_SubtitleMaximumWidth", 0.46];
    private _choiceMin = missionNamespace getVariable ["Waldo_Dialogue_ChoiceMinimumWidth", 0.20];
    private _choiceMax = missionNamespace getVariable ["Waldo_Dialogue_ChoiceMaximumWidth", 0.34];
    private _uiConfigValid = _subtitleMin > 0 && {_subtitleMin <= _subtitleMax} && {_subtitleMax <= 0.90}
        && {_choiceMin > 0} && {_choiceMin <= _choiceMax} && {_choiceMax <= 0.80}
        && {(missionNamespace getVariable ["Waldo_Dialogue_SubtitleMaximumHeight", 0.20]) > 0}
        && {(missionNamespace getVariable ["Waldo_Dialogue_ChoiceMaximumHeight", 0.42]) > 0};
    _checks pushBack ["dialogue", "responsive-ui-config", if (_uiConfigValid) then {"LOADED"} else {"ERROR"}, format ["subtitleWidth=%1-%2 choiceWidth=%3-%4 subtitleHeight=%5 choiceHeight=%6", _subtitleMin, _subtitleMax, _choiceMin, _choiceMax, missionNamespace getVariable ["Waldo_Dialogue_SubtitleMaximumHeight", 0.20], missionNamespace getVariable ["Waldo_Dialogue_ChoiceMaximumHeight", 0.42]]];
    private _version = missionNamespace getVariable ["Waldo_Dialogue_StateVersion", -1];
    _checks pushBack ["dialogue", "snapshot-authority", if (_version >= 0) then {"LOADED"} else {"ERROR"}, format ["version=%1 publicArchetypes=%2 publicConversations=%3", _version, count (missionNamespace getVariable ["Waldo_Dialogue_PublicArchetypeIds", []]), count (missionNamespace getVariable ["Waldo_Conversation_PublicIds", []])]];
};

if (hasInterface) then {
    private _ready = missionNamespace getVariable ["Waldo_Dialogue_StateReady", false];
    private _version = missionNamespace getVariable ["Waldo_Dialogue_LocalStateVersion", -1];
    private _speakers = missionNamespace getVariable ["Waldo_Dialogue_LocalSpeakers", []];
    private _aceReady = !(isNil "ace_interact_menu_fnc_createAction");
    private _invalidActions = _speakers select {
        isNull _x || {
            private _paths = _x getVariable ["Waldo_Dialogue_LocalAcePaths", []];
            private _ids = _x getVariable ["Waldo_Dialogue_LocalActionIds", []];
            if (_aceReady) then {count _paths == 0} else {count _ids == 0}
        }
    };
    _checks pushBack ["dialogue", "ordered-client-snapshot", if (_ready && {_version >= 0}) then {"LOADED"} else {"ERROR"}, format ["ready=%1 version=%2 speakers=%3", _ready, _version, count _speakers]];
    _checks pushBack ["dialogue", "local-actions", if (count _invalidActions == 0) then {if (count _speakers > 0) then {"ACTIVE"} else {"UNCONFIGURED"}} else {"ERROR"}, format ["speakers=%1 invalid=%2 mode=%3", count _speakers, _invalidActions apply {if (isNull _x) then {"NULL"} else {netId _x}}, if (_aceReady) then {"ACE"} else {"VANILLA"}]];
    private _session = uiNamespace getVariable ["Waldo_Conversation_ChoiceSession", ""];
    private _controls = uiNamespace getVariable ["Waldo_Conversation_ChoiceControls", []];
    private _buttons = uiNamespace getVariable ["Waldo_Conversation_ChoiceButtons", []];
    private _handler = uiNamespace getVariable ["Waldo_Conversation_ChoiceKeyHandler", -1];
    private _display = uiNamespace getVariable ["Waldo_Conversation_ChoiceDisplay", displayNull];
    private _resolvedTheme = [] call Waldo_fnc_UiTheme;
    private _uiCoherent = if (_session == "") then {
        _controls isEqualTo [] && {_buttons isEqualTo []} && {_handler < 0} && {isNull _display}
    } else {
        count _controls >= 4 && {count _buttons > 0} && {_handler < 0} && {!isNull _display}
    };
    _checks pushBack ["dialogue", "choice-ui-cleanup", if (_uiCoherent) then {if (_session == "") then {"LOADED"} else {"ACTIVE"}} else {"ERROR"}, format ["session=%1 controls=%2 buttons=%3 modal=%4 keyHandler=%5 theme=%6 colourVision=%7", if (_session == "") then {"NONE"} else {_session}, count _controls, count _buttons, !isNull _display, _handler, _resolvedTheme getOrDefault ["id", "UNKNOWN"], _resolvedTheme getOrDefault ["colourVision", "UNKNOWN"]]];
};

["dialogue", _checks] call Waldo_fnc_DiagnosticFeatureReport

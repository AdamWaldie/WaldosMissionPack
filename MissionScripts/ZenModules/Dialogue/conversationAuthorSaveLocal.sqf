/*
 * Author: WaldoTheWarfighter
 * Commits the visible Conversation Author form fields into the selected mission-session draft,
 * including reference-safe node renaming.
 * Locality/authority: curator interface only; this mutates no server or world state.
 * Repeat/JIP behaviour: repeat-safe local snapshot update; drafts end with the mission session.
 * Arguments: editor DISPLAY. Return Value: BOOL.
 * Current callers: Conversation Author selection, mutation, validation, submission and export paths.
 * Example: [_display] call Waldo_fnc_ConversationAuthorSaveLocal;
 */
params [["_display", displayNull, [displayNull]]];
if (isNull _display || {_display getVariable ["WaldoConvAuthor_Refreshing", false]}) exitWith {false};
private _drafts = _display getVariable ["WaldoConvAuthor_Drafts", []];
private _draftIndex = _display getVariable ["WaldoConvAuthor_DraftIndex", 0];
if (_draftIndex < 0 || {_draftIndex >= count _drafts}) exitWith {false};
private _definition = _drafts select _draftIndex;
_definition params ["_id", "_nodes", "_startNode"];
private _nameIssue = "";
private _parseTiming = {
    private _text = toUpperANSI ctrlText _this;
    if (_text in ["", "AUTO", "-1"]) exitWith {-1};
    parseNumber _text
};
private _nodeIndex = (_display getVariable ["WaldoConvAuthor_NodeIndex", 0]) min ((count _nodes - 1) max 0);
if (count _nodes > 0) then {
    private _node = _nodes select _nodeIndex;
    _node params ["_oldNodeId", "_lines", "_choices", "_next"];
    private _lineIndex = _display getVariable ["WaldoConvAuthor_LineIndex", 0];
    if (_lineIndex >= 0 && {_lineIndex < count _lines}) then {
        private _soundCombo = _display getVariable ["WaldoConvAuthor_SoundCombo", controlNull];
        private _gestureCombo = _display getVariable ["WaldoConvAuthor_GestureCombo", controlNull];
        _lines set [_lineIndex, [
            ctrlText (_display getVariable ["WaldoConvAuthor_LineText", controlNull]),
            if (lbCurSel _soundCombo >= 0) then {_soundCombo lbData lbCurSel _soundCombo} else {""},
            (_display getVariable ["WaldoConvAuthor_SoundDuration", controlNull]) call _parseTiming,
            (_display getVariable ["WaldoConvAuthor_TextDuration", controlNull]) call _parseTiming,
            if (lbCurSel _gestureCombo >= 0) then {_gestureCombo lbData lbCurSel _gestureCombo} else {""}
        ]];
    };
    private _choiceIndex = _display getVariable ["WaldoConvAuthor_ChoiceIndex", 0];
    if (_choiceIndex >= 0 && {_choiceIndex < count _choices}) then {
        private _destinationCombo = _display getVariable ["WaldoConvAuthor_ChoiceDestination", controlNull];
        _choices set [_choiceIndex, [
            ctrlText (_display getVariable ["WaldoConvAuthor_ChoiceLabel", controlNull]),
            if (lbCurSel _destinationCombo >= 0) then {_destinationCombo lbData lbCurSel _destinationCombo} else {""},
            toUpperANSI ctrlText (_display getVariable ["WaldoConvAuthor_ChoiceId", controlNull])
        ]];
    };
    private _nextCombo = _display getVariable ["WaldoConvAuthor_AutoNext", controlNull];
    _next = if (lbCurSel _nextCombo >= 0) then {_nextCombo lbData lbCurSel _nextCombo} else {""};
    private _newNodeId = toUpperANSI ctrlText (_display getVariable ["WaldoConvAuthor_NodeId", controlNull]);
    private _otherIds = (_nodes select {_x isNotEqualTo _node}) apply {_x param [0, ""]};
    private _filtered = [_newNodeId, "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"] call BIS_fnc_filterString;
    if (_newNodeId == "") then {
        _nameIssue = "Part name was not changed: enter at least one letter, number, or underscore.";
        _newNodeId = _oldNodeId;
    } else {
        if (_filtered != _newNodeId || {count _newNodeId > 64}) then {
            _nameIssue = "Part name was not changed: use no more than 64 capital letters, numbers, or underscores.";
            _newNodeId = _oldNodeId;
        } else {
            if (_newNodeId in _otherIds) then {
                _nameIssue = "Part name was not changed because another part already uses that name.";
                _newNodeId = _oldNodeId;
            };
        };
    };
    if (_newNodeId != _oldNodeId) then {
        if (_startNode == _oldNodeId) then {_startNode = _newNodeId};
        {
            if ((_x param [3, ""]) == _oldNodeId) then {_x set [3, _newNodeId]};
            {if ((_x param [1, ""]) == _oldNodeId) then {_x set [1, _newNodeId]}} forEach (_x param [2, []]);
        } forEach _nodes;
    };
    _nodes set [_nodeIndex, [_newNodeId, _lines, _choices, _next]];
};
private _idEdit = _display getVariable ["WaldoConvAuthor_Id", controlNull];
_id = toUpperANSI ctrlText _idEdit;
_idEdit ctrlSetText _id;
private _startCombo = _display getVariable ["WaldoConvAuthor_StartNode", controlNull];
if (lbCurSel _startCombo >= 0) then {
    private _selectedStart = _startCombo lbData lbCurSel _startCombo;
    if (_selectedStart in (_nodes apply {_x param [0, ""]})) then {_startNode = _selectedStart};
};
_definition = [_id, _nodes, _startNode];
_drafts set [_draftIndex, _definition];
_display setVariable ["WaldoConvAuthor_Drafts", _drafts];
_display setVariable ["WaldoConvAuthor_NameIssue", _nameIssue];
private _liveFingerprint = (missionNamespace getVariable ["Waldo_Conversation_AuthorLiveFingerprints", createHashMap]) getOrDefault [_id, ""];
private _dirty = _liveFingerprint != "" && {_liveFingerprint != str _definition};
_display setVariable ["WaldoConvAuthor_Dirty", _dirty];
if (_dirty) then {_display setVariable ["WaldoConvAuthor_LastWorkflowState", "DIRTY"]};
missionNamespace setVariable ["Waldo_Conversation_AuthorDrafts", _drafts];
true

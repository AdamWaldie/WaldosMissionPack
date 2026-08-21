/*
 * Author: WaldoTheWarfighter
 * Shows the initiating player a themed response panel on an engine-owned modal display. Gameplay
 * bindings cannot fire through this display; choices and cancellation use visible buttons.
 * Locality/authority: interface local and accepts server remote execution only; sends choice IDs only.
 * Repeat/JIP behaviour: replaces any previous panel and records the display for cleanup. A local
 * watchdog independently returns control if the entities/session/range cease to be valid.
 * Arguments: speaker OBJECT, session ID STRING, choices ARRAY<[id,label,enabled]>. Return Value: BOOL.
 * Current caller: ConversationRunServer. Example: server remote execution to the initiating player.
 */
params [["_speaker", objNull, [objNull]], ["_sessionId", "", [""]], ["_choices", [], [[]]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {isNull _speaker} || {count _choices == 0}) exitWith {false};
[_sessionId] call Waldo_fnc_ConversationHideChoicesLocal;
private _gameDisplay = findDisplay 46;
if (isNull _gameDisplay) exitWith {false};
private _display = _gameDisplay createDisplay "RscDisplayEmpty";
if (isNull _display) exitWith {false};
uiNamespace setVariable ["Waldo_Conversation_ChoiceDisplay", _display];
private _theme = [] call Waldo_fnc_UiTheme;
private _controls = [];
private _maximumWidth = safeZoneW * ((missionNamespace getVariable ["Waldo_Dialogue_ChoiceMaximumWidth", 0.34]) max 0.25 min 0.80);
private _minimumWidth = safeZoneW * ((missionNamespace getVariable ["Waldo_Dialogue_ChoiceMinimumWidth", 0.20]) max 0.15 min 0.70);
_minimumWidth = _minimumWidth min _maximumWidth;
private _maximumHeight = safeZoneH * ((missionNamespace getVariable ["Waldo_Dialogue_ChoiceMaximumHeight", 0.42]) max 0.20 min 0.75);
private _minimumRowHeight = safeZoneH * ((missionNamespace getVariable ["Waldo_Dialogue_ChoiceMinimumRowHeight", 0.038]) max 0.026 min 0.10);
private _textScale = (missionNamespace getVariable ["Waldo_Dialogue_ChoiceTextScale", 0.90]) max 0.65 min 1.35;
private _rowGap = safeZoneH * 0.004;
private _headerHeight = safeZoneH * 0.055;
private _horizontalPadding = safeZoneW * 0.024;
private _panelY = safeZoneY + safeZoneH * 0.54;
private _frame = _display ctrlCreate ["RscText", -1];
_frame ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.008,0.018,0.03,0.95]]);
_controls pushBack _frame;
private _title = _display ctrlCreate ["RscText", -1];
_title ctrlSetText "YOUR RESPONSE"; _title ctrlSetFont (_theme getOrDefault ["fontBold", "RobotoCondensedBold"]);
_title ctrlSetTextColor (_theme getOrDefault ["accent", [0.1,0.46,0.76,1]]);
_controls pushBack _title;
private _group = _display ctrlCreate ["RscControlsGroup", -1];
_group ctrlSetPosition [safeZoneX, safeZoneY, _maximumWidth - _horizontalPadding, _maximumHeight - _headerHeight];
_group ctrlCommit 0;
_controls pushBack _group;
private _buttons = [];
private _rows = [];
private _contentWidth = ctrlTextWidth _title;
{
    _x params ["_choiceId", "_label", ["_enabled", true, [true]]];
    private _button = _display ctrlCreate ["RscStructuredText", -1, _group];
    _button ctrlSetStructuredText parseText format ["<t align='left' valign='middle' font='%1' color='%2' size='%3'>%4</t>", _theme getOrDefault ["font", "RobotoCondensed"], if (_enabled) then {_theme getOrDefault ["textHex", "#FFFFFF"]} else {_theme getOrDefault ["mutedHex", "#9FB8D1"]}, _textScale, _label];
    _button ctrlSetBackgroundColor (_theme getOrDefault ["button", [0.035,0.14,0.23,1]]);
    _button ctrlSetTooltip _label;
    _button setVariable ["Waldo_Conversation_ChoiceId", _choiceId];
    _button setVariable ["Waldo_Conversation_ChoiceEnabled", _enabled];
    _button setVariable ["Waldo_Conversation_BaseColour", _theme getOrDefault ["button", [0.035,0.14,0.23,1]]];
    _button setVariable ["Waldo_Conversation_HoverColour", _theme getOrDefault ["buttonActive", [0.08,0.45,0.75,1]]];
    _button ctrlEnable _enabled;
    _button ctrlSetPosition [0, 0, _maximumWidth - _horizontalPadding, _maximumHeight];
    _button ctrlCommit 0;
    _contentWidth = _contentWidth max (ctrlTextWidth _button);
    _button ctrlAddEventHandler ["MouseEnter", {params ["_control"]; if (_control getVariable ["Waldo_Conversation_ChoiceEnabled", false]) then {_control ctrlSetBackgroundColor (_control getVariable ["Waldo_Conversation_HoverColour", [0.08,0.45,0.75,1]])}}];
    _button ctrlAddEventHandler ["MouseExit", {params ["_control"]; _control ctrlSetBackgroundColor (_control getVariable ["Waldo_Conversation_BaseColour", [0.035,0.14,0.23,1]])}];
    _button ctrlAddEventHandler ["MouseButtonUp", {
        params ["_control", "_mouseButton"];
        if (_mouseButton != 0 || {!(_control getVariable ["Waldo_Conversation_ChoiceEnabled", false])}) exitWith {false};
        private _speaker = uiNamespace getVariable ["Waldo_Conversation_ChoiceSpeaker", objNull];
        private _session = uiNamespace getVariable ["Waldo_Conversation_ChoiceSession", ""];
        [_speaker, player, _session, _control getVariable ["Waldo_Conversation_ChoiceId", ""]] remoteExecCall ["Waldo_fnc_ConversationChooseServer", 2];
        [_session] call Waldo_fnc_ConversationHideChoicesLocal;
        true
    }];
    _buttons pushBack _button; _rows pushBack _button; _controls pushBack _button;
} forEach _choices;
private _cancelButton = _display ctrlCreate ["RscStructuredText", -1, _group];
_cancelButton ctrlSetStructuredText parseText format ["<t align='center' valign='middle' font='%1' color='%2' size='%3'>Cancel conversation</t>", _theme getOrDefault ["font", "RobotoCondensed"], _theme getOrDefault ["mutedHex", "#9FB8D1"], _textScale];
_cancelButton ctrlSetBackgroundColor (_theme getOrDefault ["panelAlt", [0.035,0.065,0.095,1]]);
_cancelButton setVariable ["Waldo_Conversation_BaseColour", _theme getOrDefault ["panelAlt", [0.035,0.065,0.095,1]]];
_cancelButton setVariable ["Waldo_Conversation_HoverColour", _theme getOrDefault ["header", [0.018,0.19,0.34,1]]];
_cancelButton ctrlSetPosition [0, 0, _maximumWidth - _horizontalPadding, _maximumHeight];
_cancelButton ctrlCommit 0;
_contentWidth = _contentWidth max (ctrlTextWidth _cancelButton);
_cancelButton ctrlAddEventHandler ["MouseEnter", {params ["_control"]; _control ctrlSetBackgroundColor (_control getVariable ["Waldo_Conversation_HoverColour", [0.018,0.19,0.34,1]])}];
_cancelButton ctrlAddEventHandler ["MouseExit", {params ["_control"]; _control ctrlSetBackgroundColor (_control getVariable ["Waldo_Conversation_BaseColour", [0.035,0.065,0.095,1]])}];
_cancelButton ctrlAddEventHandler ["MouseButtonUp", {
    params ["_control", "_mouseButton"];
    if (_mouseButton != 0) exitWith {false};
    private _speaker = uiNamespace getVariable ["Waldo_Conversation_ChoiceSpeaker", objNull];
    private _session = uiNamespace getVariable ["Waldo_Conversation_ChoiceSession", ""];
    [_speaker, player, _session, "PLAYER_CANCELLED"] remoteExecCall ["Waldo_fnc_ConversationCancel", 2];
    [_session] call Waldo_fnc_ConversationHideChoicesLocal;
    true
}];
_rows pushBack _cancelButton; _controls pushBack _cancelButton;
private _width = (_contentWidth + _horizontalPadding) max _minimumWidth min _maximumWidth;
private _panelX = safeZoneX + ((safeZoneW - _width) / 2);
private _innerWidth = _width - _horizontalPadding;
private _contentHeight = 0;
{
    _x ctrlSetPosition [0, _contentHeight, _innerWidth, _maximumHeight];
    _x ctrlCommit 0;
    private _rowHeight = ((ctrlTextHeight _x) + safeZoneH * 0.014) max _minimumRowHeight min (safeZoneH * 0.16);
    _x ctrlSetPosition [0, _contentHeight, _innerWidth, _rowHeight];
    _x ctrlCommit 0;
    _contentHeight = _contentHeight + _rowHeight + _rowGap;
} forEach _rows;
private _groupHeight = _contentHeight min (_maximumHeight - _headerHeight);
private _height = _headerHeight + _groupHeight + safeZoneH * 0.012;
_frame ctrlSetPosition [_panelX, _panelY, _width, _height]; _frame ctrlCommit 0;
_title ctrlSetPosition [_panelX + (_horizontalPadding / 2), _panelY + safeZoneH * 0.008, _innerWidth, safeZoneH * 0.032]; _title ctrlCommit 0;
_group ctrlSetPosition [_panelX + (_horizontalPadding / 2), _panelY + safeZoneH * 0.046, _innerWidth, _groupHeight]; _group ctrlCommit 0;
uiNamespace setVariable ["Waldo_Conversation_ChoiceSpeaker", _speaker];
uiNamespace setVariable ["Waldo_Conversation_ChoiceSession", _sessionId];
uiNamespace setVariable ["Waldo_Conversation_ChoiceControls", _controls];
uiNamespace setVariable ["Waldo_Conversation_ChoiceButtons", _buttons];
uiNamespace setVariable ["Waldo_Conversation_ChoiceKeyHandler", -1];
_display displayAddEventHandler ["Unload", {
    private _session = uiNamespace getVariable ["Waldo_Conversation_ChoiceSession", ""];
    if (_session == "") exitWith {false};
    [uiNamespace getVariable ["Waldo_Conversation_ChoiceSpeaker", objNull], player, _session, "PLAYER_CANCELLED"] remoteExecCall ["Waldo_fnc_ConversationCancel", 2];
    [_session] spawn {params ["_session"]; uiSleep 0; [_session] call Waldo_fnc_ConversationHideChoicesLocal};
    false
}];
["CONVERSATION_CHOICES", _controls, ["CENTER", "BOTTOM_CENTER"], true] call Waldo_fnc_RegisterUiReservationLocal;
[_speaker, player, _sessionId, _display] spawn {
    params ["_speaker", "_caller", "_sessionId", "_display"];
    private _reason = "";
    waitUntil {
        uiSleep 0.1;
        if ((uiNamespace getVariable ["Waldo_Conversation_ChoiceSession", ""]) != _sessionId) exitWith {true};
        if (isNull _display) exitWith {_reason = "DISPLAY_LOST"; true};
        if (isNull _speaker) exitWith {_reason = "SPEAKER_DELETED"; true};
        if (isNull _caller || {player != _caller}) exitWith {_reason = "CALLER_REPLACED"; true};
        if (!alive _speaker || {lifeState _speaker in ["INCAPACITATED", "DEAD"]}) exitWith {_reason = "SPEAKER_UNAVAILABLE"; true};
        if (!alive _caller || {lifeState _caller in ["INCAPACITATED", "DEAD"]}) exitWith {_reason = "CALLER_UNAVAILABLE"; true};
        if (!(_speaker getVariable ["Waldo_Dialogue_Available", false]) || {!(_speaker getVariable ["Waldo_Dialogue_Occupied", false])}) exitWith {_reason = "SESSION_LOST"; true};
        if (_speaker distance _caller > (missionNamespace getVariable ["Waldo_Dialogue_CancelDistance", 6])) exitWith {_reason = "OUT_OF_RANGE"; true};
        false
    };
    if (_reason != "" && {(uiNamespace getVariable ["Waldo_Conversation_ChoiceSession", ""]) == _sessionId}) then {
        if (!isNull _speaker && {!isNull _caller}) then {[_speaker, _caller, _sessionId, _reason] remoteExecCall ["Waldo_fnc_ConversationCancel", 2]};
        [_sessionId] call Waldo_fnc_ConversationHideChoicesLocal;
        diag_log format ["[WMP CONVERSATION] Local response panel fail-open cleanup session=%1 reason=%2 owner=%3.", _sessionId, _reason, clientOwner];
    };
};
true

/*
 * Author: WaldoTheWarfighter
 * Shows one themed, readable subtitle in the shared bottom-centre WMP UI lane.
 * Locality/authority: interface-local and accepts server remote execution only.
 * Repeat/JIP behaviour: a token ensures an older line cannot hide a newer one.
 * Arguments: speaker name STRING, text STRING, duration NUMBER, token STRING. Return Value: BOOL.
 * Current callers: simple and advanced server workers. Example: server remote execution to nearby players.
 */
params [["_speakerName", "", [""]], ["_text", "", [""]], ["_duration", 1.5, [0]], ["_token", "", [""]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {_text == ""}) exitWith {false};
private _display = findDisplay 46;
if (isNull _display) exitWith {false};
private _theme = [] call Waldo_fnc_UiTheme;
private _frame = uiNamespace getVariable ["Waldo_Dialogue_SubtitleFrame", controlNull];
private _control = uiNamespace getVariable ["Waldo_Dialogue_SubtitleText", controlNull];
if (isNull _frame) then {_frame = _display ctrlCreate ["RscText", -1]; uiNamespace setVariable ["Waldo_Dialogue_SubtitleFrame", _frame]};
if (isNull _control) then {_control = _display ctrlCreate ["RscStructuredText", -1]; uiNamespace setVariable ["Waldo_Dialogue_SubtitleText", _control]};
_frame ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.008, 0.018, 0.03, 0.95]]);
_control ctrlSetBackgroundColor [0,0,0,0];
private _textScale = (missionNamespace getVariable ["Waldo_Dialogue_SubtitleTextScale", 0.90]) max 0.65 min 1.35;
_control ctrlSetStructuredText parseText format ["<t align='center' font='%1' color='%2' size='%3'><t font='%4' color='%5'>%6</t><br/>%7</t>", _theme getOrDefault ["font", "RobotoCondensed"], _theme getOrDefault ["textHex", "#FFFFFF"], _textScale, _theme getOrDefault ["fontBold", "RobotoCondensedBold"], _theme getOrDefault ["accentHex", "#79C7FF"], _speakerName, _text];
private _maximumWidth = safeZoneW * ((missionNamespace getVariable ["Waldo_Dialogue_SubtitleMaximumWidth", 0.46]) max 0.25 min 0.90);
private _minimumWidth = safeZoneW * ((missionNamespace getVariable ["Waldo_Dialogue_SubtitleMinimumWidth", 0.22]) max 0.15 min 0.80);
_minimumWidth = _minimumWidth min _maximumWidth;
private _horizontalPadding = safeZoneW * 0.022;
private _maximumHeight = safeZoneH * ((missionNamespace getVariable ["Waldo_Dialogue_SubtitleMaximumHeight", 0.20]) max 0.08 min 0.45);
_control ctrlSetPosition [safeZoneX, safeZoneY + safeZoneH * 0.76, _maximumWidth - _horizontalPadding, _maximumHeight];
_control ctrlCommit 0;
private _width = ((ctrlTextWidth _control) + _horizontalPadding) max _minimumWidth min _maximumWidth;
private _panelX = safeZoneX + ((safeZoneW - _width) / 2);
_control ctrlSetPosition [_panelX + (_horizontalPadding / 2), safeZoneY + safeZoneH * 0.76, _width - _horizontalPadding, _maximumHeight];
_control ctrlCommit 0;
private _height = ((ctrlTextHeight _control) + safeZoneH * 0.018) max (safeZoneH * 0.055) min _maximumHeight;
private _y = safeZoneY + safeZoneH * 0.90 - _height;
_frame ctrlSetPosition [_panelX, _y, _width, _height];
_control ctrlSetPosition [_panelX + (_horizontalPadding / 2), _y + safeZoneH * 0.007, _width - _horizontalPadding, _height - safeZoneH * 0.010];
_frame ctrlCommit 0; _control ctrlCommit 0; _frame ctrlShow true; _control ctrlShow true;
uiNamespace setVariable ["Waldo_Dialogue_SubtitleToken", _token];
["DIALOGUE_SUBTITLE", [_frame, _control], ["BOTTOM_CENTER"], true] call Waldo_fnc_RegisterUiReservationLocal;
[_token, _duration max 0.1] spawn {params ["_token", "_duration"]; uiSleep _duration; if ((uiNamespace getVariable ["Waldo_Dialogue_SubtitleToken", ""]) == _token) then {[_token] call Waldo_fnc_DialogueHideLocal}};
true

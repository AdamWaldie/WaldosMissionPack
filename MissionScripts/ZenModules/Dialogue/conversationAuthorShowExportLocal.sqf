/*
 * Author: WaldoTheWarfighter
 * Shows generated Conversation Author code inside the existing editor so a curator can inspect and
 * manually copy it even when Arma or the operating system rejects copyToClipboard.
 * Locality/authority: interface-local presentation only; no server state is read or changed.
 * Repeat/JIP behaviour: replaces any existing export preview on the same display and is safe to
 * reopen. The preview exists only while the current editor display remains open.
 * Arguments: editor DISPLAY, format STRING CONFIG or SCRIPT, generated code STRING.
 * Return Value: ARRAY of created controls, or an empty ARRAY when the display is unavailable.
 * Current caller: Waldo_fnc_ConversationAuthorExportLocal.
 * Example: [_display, "CONFIG", str _definition] call Waldo_fnc_ConversationAuthorShowExportLocal;
 */
params [
    ["_display", displayNull, [displayNull]],
    ["_format", "CONFIG", [""]],
    ["_text", "", [""]]
];
if (isNull _display) exitWith {[]};

{
    if (!isNull _x) then {ctrlDelete _x};
} forEach (_display getVariable ["WaldoConvAuthor_ExportPreviewControls", []]);

private _theme = _display getVariable ["WaldoEcoCore_PromptTheme", [] call Waldo_fnc_UiTheme];
(_display getVariable ["WaldoEcoCore_PromptContentBounds", [safeZoneX + safeZoneW * 0.08, safeZoneY + safeZoneH * 0.12, safeZoneW * 0.84, safeZoneH * 0.76]]) params ["_boundsX", "_boundsY", "_boundsW", "_boundsH"];
private _panelX = _boundsX + (_boundsW * 0.04);
private _panelY = _boundsY + (_boundsH * 0.07);
private _panelW = _boundsW * 0.92;
private _panelH = _boundsH * 0.82;
private _innerX = _panelX + (_panelW * 0.025);
private _innerW = _panelW * 0.95;
private _controls = [];
private _makeControl = {
    params ["_class", "_position", ["_idc", -1]];
    private _control = _display ctrlCreate [_class, _idc];
    _control ctrlSetPosition _position;
    _control ctrlCommit 0;
    _controls pushBack _control;
    _control
};

private _shield = ["RscText", [_boundsX, _boundsY, _boundsW, _boundsH], 9300] call _makeControl;
_shield ctrlSetBackgroundColor [0.005, 0.012, 0.02, 0.995];

private _panel = ["RscText", [_panelX, _panelY, _panelW, _panelH], 9301] call _makeControl;
_panel ctrlSetBackgroundColor (_theme getOrDefault ["panelAlt", [0.035, 0.065, 0.095, 0.99]]);

private _title = ["RscText", [_innerX, _panelY + (_panelH * 0.035), _innerW, _panelH * 0.065], 9302] call _makeControl;
_title ctrlSetText (if (toUpperANSI _format == "SCRIPT") then {"SERVER SCRIPT CODE READY"} else {"MISSION CONFIG CODE READY"});
_title ctrlSetTextColor (_theme getOrDefault ["accent", [0.25, 0.72, 1, 1]]);

private _help = ["RscStructuredText", [_innerX, _panelY + (_panelH * 0.105), _innerW, _panelH * 0.095], 9303] call _makeControl;
_help ctrlSetStructuredText parseText "<t size='0.68' color='#FFD166'>CODE ONLY — this does not save or update any NPC.</t><br/><t size='0.64'>The code was also sent to the clipboard. If paste is empty, click the code, press Ctrl+A, then Ctrl+C.</t>";

private _code = ["RscEditMulti", [_innerX, _panelY + (_panelH * 0.215), _innerW, _panelH * 0.61], 9304] call _makeControl;
_code ctrlSetText _text;
_code ctrlSetTooltip "Generated code. Click here, then use Ctrl+A and Ctrl+C to copy it manually.";
_code ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.015, 0.03, 0.045, 1]]);
_code ctrlSetTextColor (_theme getOrDefault ["text", [0.9, 0.96, 1, 1]]);

private _copy = ["RscButton", [_innerX, _panelY + (_panelH * 0.85), _panelW * 0.30, _panelH * 0.075], 9305] call _makeControl;
_copy ctrlSetText "COPY TO CLIPBOARD";
_copy ctrlSetTooltip "Try copying the generated code to the Windows clipboard again.";

private _back = ["RscButton", [_panelX + (_panelW * 0.68), _panelY + (_panelH * 0.85), _panelW * 0.295, _panelH * 0.075], 9306] call _makeControl;
_back ctrlSetText "BACK TO EDITOR";
_back ctrlSetTooltip "Return to the conversation editor without changing the draft.";

_display setVariable ["WaldoConvAuthor_ExportPreviewText", _text];
_display setVariable ["WaldoConvAuthor_ExportPreviewControls", _controls];
_display setVariable ["WaldoConvAuthor_ExportPreviewButtons", [_copy, _back]];

_copy ctrlAddEventHandler ["ButtonClick", {
    private _display = ctrlParent (_this select 0);
    copyToClipboard (_display getVariable ["WaldoConvAuthor_ExportPreviewText", ""]);
    ["CONVERSATION", "Copy requested. If paste is still empty, use Ctrl+A then Ctrl+C in the code box.", "SUCCESS", "CONVERSATION_AUTHOR_EXPORT_COPY", 7]
        call Waldo_fnc_FeatureNotifyLocal;
}];
_back ctrlAddEventHandler ["ButtonClick", {
    private _display = ctrlParent (_this select 0);
    {
        if (!isNull _x) then {ctrlDelete _x};
    } forEach (_display getVariable ["WaldoConvAuthor_ExportPreviewControls", []]);
    _display setVariable ["WaldoConvAuthor_ExportPreviewControls", []];
    _display setVariable ["WaldoConvAuthor_ExportPreviewButtons", []];
    _display setVariable ["WaldoConvAuthor_ExportPreviewText", ""];
}];

ctrlSetFocus _code;
_controls

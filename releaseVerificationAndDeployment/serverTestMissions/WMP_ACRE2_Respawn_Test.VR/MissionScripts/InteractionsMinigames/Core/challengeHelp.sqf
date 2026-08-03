/*
 * Author: WaldoTheWarfighter
 * Adds a repeat-safe, on-demand help card to an active grid-aligned field procedure.
 *
 * Arguments: 0: display <DISPLAY>; 1: name <STRING>; 2: objective <STRING>;
 * 3: controls <STRING>; 4: operational hint <STRING>.
 * Return Value: Nothing; stores and creates help controls on the supplied display.
 *
 * Example: [_display, "BREAKER", "Restore power", "Select links", "Trace the circuit"] call Waldo_fnc_MiniGameChallengeHelp;
 * Current caller: ChallengeUi while constructing an interaction-procedure display.
 */
disableSerialization;
params [
    ["_display", displayNull, [displayNull]],
    ["_name", "EQUIPMENT", [""]],
    ["_objective", "Complete the procedure.", [""]],
    ["_controls", "Use the displayed controls.", [""]],
    ["_hint", "Follow the instrument labels.", [""]]
];
if (isNull _display) exitWith {};
_display setVariable ["Waldo_MG_Help_Name", _name];
_display setVariable ["Waldo_MG_Help_Objective", _objective];
_display setVariable ["Waldo_MG_Help_Controls", _controls];
_display setVariable ["Waldo_MG_Help_Hint", _hint];
_display setVariable ["Waldo_MG_Help_ControlsCreated", []];
private _bounds = _display getVariable ["Waldo_IMG_Bounds", [safeZoneX, safeZoneY, safeZoneW, safeZoneH]];
_bounds params ["_canvasX", "_canvasY", "_canvasW", "_canvasH"];
private _cellW = _canvasW / 40;
private _cellH = _canvasH / 25;
private _theme = (_display getVariable ["Waldo_IMG_Profile", createHashMap]) getOrDefault ["uiTheme", [] call Waldo_fnc_UiTheme];
private _button = _display ctrlCreate ["RscButton", -1];
_button ctrlSetPosition [_canvasX + (34.0 * _cellW), _canvasY + (0.35 * _cellH), 4.5 * _cellW, 1.05 * _cellH];
_button ctrlSetText "? HELP";
_button ctrlSetFontHeight ((0.62 * _cellH) max 0.018);
_button ctrlSetBackgroundColor (_theme getOrDefault ["panelAlt", [0.045, 0.05, 0.045, 0.99]]);
_button ctrlSetTextColor (_theme getOrDefault ["text", [0.92, 0.90, 0.82, 1]]);
_button ctrlSetActiveColor (_theme getOrDefault ["accentActive", [0.82, 0.58, 0.18, 1]]);
_button ctrlSetFont (_theme getOrDefault ["fontBold", "RobotoCondensedBold"]);
_button ctrlSetTooltip "Open the equipment operating procedure";
_button ctrlCommit 0;
private _shellControls = _display getVariable ["Waldo_MG_UI_ShellControls", []];
_shellControls pushBack _button;
_display setVariable ["Waldo_MG_UI_ShellControls", _shellControls];
_display setVariable ["Waldo_MG_Help_Close", {
    params ["_display"];
    private _controls = _display getVariable ["Waldo_MG_Help_ControlsCreated", []];
    private _hiddenControls = _display getVariable ["Waldo_MG_Help_HiddenControls", []];
    _display setVariable ["Waldo_MG_Help_ControlsCreated", []];
    _display setVariable ["Waldo_MG_Help_HiddenControls", []];
    {
        _x params ["_control", "_wasShown"];
        if (!isNull _control) then {_control ctrlShow _wasShown;};
    } forEach _hiddenControls;
    private _shellControls = _display getVariable ["Waldo_MG_UI_ShellControls", []];
    _shellControls = _shellControls select {!(_x in _controls)};
    _display setVariable ["Waldo_MG_UI_ShellControls", _shellControls];
    [_controls] spawn {
        params ["_controls"];
        uiSleep 0;
        {if (!isNull _x) then {ctrlDelete _x;};} forEach _controls;
    };
}];
_button ctrlAddEventHandler ["ButtonClick", {
    params ["_button"];
    private _display = ctrlParent _button;
    if (count (_display getVariable ["Waldo_MG_Help_ControlsCreated", []]) > 0) exitWith {
        [_display] call (_display getVariable ["Waldo_MG_Help_Close", {}]);
    };
    private _bounds = _display getVariable ["Waldo_IMG_Bounds", [safeZoneX, safeZoneY, safeZoneW, safeZoneH]];
    _bounds params ["_canvasX", "_canvasY", "_canvasW", "_canvasH"];
    private _cellW = _canvasW / 40;
    private _cellH = _canvasH / 25;
    private _profile = _display getVariable ["Waldo_IMG_Profile", createHashMap];
    private _theme = _profile getOrDefault ["uiTheme", [] call Waldo_fnc_UiTheme];
    private _largeText = (_profile getOrDefault ["accessibility", createHashMap]) getOrDefault ["largeText", false];
    private _created = [];
    private _hidden = [];
    {
        if (!isNull _x) then {
            _hidden pushBack [_x, ctrlShown _x];
            _x ctrlShow false;
        };
    } forEach ((_display getVariable ["Waldo_MG_UI_EquipmentControls", []]) + (_display getVariable ["Waldo_MG_UI_ShellControls", []]));
    _display setVariable ["Waldo_MG_Help_HiddenControls", _hidden];
    private _shade = _display ctrlCreate ["RscText", -1];
    _shade ctrlSetPosition [_canvasX, _canvasY, _canvasW, _canvasH];
    _shade ctrlSetBackgroundColor (_theme getOrDefault ["shade", [0, 0, 0, 0.86]]);
    _shade ctrlCommit 0;
    _created pushBack _shade;
    private _panel = _display ctrlCreate ["RscText", -1];
    _panel ctrlSetPosition [_canvasX + (4 * _cellW), _canvasY + (3 * _cellH), 32 * _cellW, 19 * _cellH];
    _panel ctrlSetBackgroundColor (_theme getOrDefault ["panelAlt", [0.12, 0.115, 0.095, 0.998]]);
    _panel ctrlCommit 0;
    _created pushBack _panel;
    private _header = _display ctrlCreate ["RscText", -1];
    _header ctrlSetPosition [_canvasX + (5 * _cellW), _canvasY + (4 * _cellH), 30 * _cellW, 2 * _cellH];
    _header ctrlSetText format ["%1 // %2", _profile getOrDefault ["briefing", "FIELD PROCEDURE"], _display getVariable ["Waldo_MG_Help_Name", "EQUIPMENT"]];
    _header ctrlSetTextColor (_theme getOrDefault ["text", [0.94, 0.92, 0.82, 1]]);
    _header ctrlSetBackgroundColor (_theme getOrDefault ["header", [0.055, 0.06, 0.055, 1]]);
    _header ctrlSetFont (_theme getOrDefault ["fontBold", "RobotoCondensedBold"]);
    _header ctrlSetFontHeight ((if (_largeText) then {0.92} else {0.78}) * _cellH);
    _header ctrlCommit 0;
    [_header, (if (_largeText) then {0.92} else {0.78}) * _cellH, 0.42 * _cellH] call Waldo_fnc_MiniGameEquipmentFitText;
    _created pushBack _header;
    private _text = _display ctrlCreate ["RscStructuredText", -1];
    _text ctrlSetPosition [_canvasX + (6 * _cellW), _canvasY + (6.7 * _cellH), 28 * _cellW, 11.5 * _cellH];
    private _textTemplate = format ["<t font='%1' size='%%1'><t color='%2'>OPERATION</t><br/>", _theme getOrDefault ["font", "RobotoCondensed"], _theme getOrDefault ["accentHex", "#E6C15A"]]
        + (_display getVariable ["Waldo_MG_Help_Objective", ""])
        + format ["<br/><br/><t color='%1'>CONTROLS</t><br/>", _theme getOrDefault ["accentHex", "#E6C15A"]]
        + (_display getVariable ["Waldo_MG_Help_Controls", ""])
        + format ["<br/><br/><t color='%1'>PROCEDURE NOTE</t><br/>", _theme getOrDefault ["accentHex", "#E6C15A"]]
        + (_display getVariable ["Waldo_MG_Help_Hint", ""])
        + format ["<br/><br/><t color='%1'>[!] ", _theme getOrDefault ["warningHex", "#F2BE55"]]
        + (_profile getOrDefault ["abortText", "ABORTING COUNTS AS FAILURE"])
        + "</t></t>";
    [_text, _textTemplate, if (_largeText) then {1.13} else {1}, 0.62] call Waldo_fnc_MiniGameEquipmentFitStructuredText;
    _created pushBack _text;
    private _close = _display ctrlCreate ["RscButton", -1];
    _close ctrlSetPosition [_canvasX + (25 * _cellW), _canvasY + (19.3 * _cellH), 9 * _cellW, 1.7 * _cellH];
    _close ctrlSetText "RETURN TO EQUIPMENT";
    _close ctrlSetBackgroundColor (_theme getOrDefault ["header", [0.04, 0.20, 0.34, 1]]);
    _close ctrlSetTextColor (_theme getOrDefault ["text", [0.96, 0.96, 0.92, 1]]);
    _close ctrlSetActiveColor (_theme getOrDefault ["accentActive", [0.10, 0.48, 0.76, 1]]);
    _close ctrlSetFont (_theme getOrDefault ["fontBold", "RobotoCondensedBold"]);
    _close ctrlCommit 0;
    [_close, 0.70 * _cellH, 0.42 * _cellH] call Waldo_fnc_MiniGameEquipmentFitText;
    _close ctrlAddEventHandler ["ButtonClick", {private _display = ctrlParent (_this select 0); [_display] call (_display getVariable ["Waldo_MG_Help_Close", {}]);}];
    _created pushBack _close;
    _display setVariable ["Waldo_MG_Help_ControlsCreated", _created];
    private _shellControls = _display getVariable ["Waldo_MG_UI_ShellControls", []];
    _shellControls append _created;
    _display setVariable ["Waldo_MG_UI_ShellControls", _shellControls];
    [_display, true] call Waldo_fnc_MiniGameEquipmentValidateDisplay;
    ctrlSetFocus _close;
}];

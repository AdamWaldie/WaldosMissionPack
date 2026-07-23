/*
 * Author: Waldo
 * Adds an on-demand HOW TO PLAY overlay to an interaction challenge display. The help panel is
 * created only when opened so it always appears above the challenge's game controls.
 *
 * Arguments:
 * _display   - Display - challenge display
 * _name      - String  - challenge name
 * _objective - String  - what the player must achieve
 * _controls  - String  - mouse/keyboard controls
 * _hint      - String  - useful strategy or consequence hint
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_display, "REPAIR", "Tighten every bolt.", "Drag clockwise.", "Do not over-torque."]
 *     call Waldo_fnc_MiniGameChallengeHelp;
 */

disableSerialization;
params [
    ["_display", displayNull, [displayNull]],
    ["_name", "CHALLENGE", [""]],
    ["_objective", "Complete the interaction.", [""]],
    ["_controls", "Use the mouse to interact.", [""]],
    ["_hint", "Read the status line after every input.", [""]]
];
if (isNull _display) exitWith {};

_display setVariable ["Waldo_MG_Help_Name", _name];
_display setVariable ["Waldo_MG_Help_Objective", _objective];
_display setVariable ["Waldo_MG_Help_Controls", _controls];
_display setVariable ["Waldo_MG_Help_Hint", _hint];
_display setVariable ["Waldo_MG_Help_ControlsCreated", []];

private _button = _display ctrlCreate ["RscButtonMenu", -1];
_button ctrlSetPosition [safezoneX + 0.018 * safezoneW, safezoneY + 0.018 * safezoneH, 0.15 * safezoneW, 0.048 * safezoneH];
_button ctrlSetText "?  FIELD PROCEDURE";
_button ctrlSetTooltip "Open the equipment operating procedure";
_button ctrlCommit 0;

_display setVariable ["Waldo_MG_Help_Close", {
    params ["_disp"];
    private _controls = _disp getVariable ["Waldo_MG_Help_ControlsCreated", []];
    _disp setVariable ["Waldo_MG_Help_ControlsCreated", []];
    _controls spawn {
        params ["_deferredControls"];
        uiSleep 0;
        {if (!isNull _x) then {ctrlDelete _x;};} forEach _deferredControls;
    };
}];

_button ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = ctrlParent _ctrl;
    private _existing = _disp getVariable ["Waldo_MG_Help_ControlsCreated", []];
    if (count _existing > 0) exitWith {
        [_disp] call (_disp getVariable ["Waldo_MG_Help_Close", {}]);
    };

    private _w = (0.58 * safezoneW) min (0.84 * safezoneH);
    private _h = 0.46 * safezoneH;
    private _x = safezoneX + (safezoneW - _w) / 2;
    private _y = safezoneY + (safezoneH - _h) / 2;
    private _created = [];
    private _profile = _disp getVariable ["Waldo_IMG_Profile", createHashMap];
    private _access = _profile getOrDefault ["accessibility", createHashMap];
    private _textScale = if (_access getOrDefault ["largeText", false]) then {1.16} else {1};

    private _shade = _disp ctrlCreate ["RscText", -1];
    _shade ctrlSetPosition [safezoneX, safezoneY, safezoneW, safezoneH];
    _shade ctrlSetBackgroundColor [0, 0, 0, 0.78];
    _shade ctrlCommit 0;
    _created pushBack _shade;

    private _panel = _disp ctrlCreate ["RscText", -1];
    _panel ctrlSetPosition [_x, _y, _w, _h];
    _panel ctrlSetBackgroundColor [0.12, 0.115, 0.095, 0.995];
    _panel ctrlCommit 0;
    _created pushBack _panel;

    private _header = _disp ctrlCreate ["RscText", -1];
    _header ctrlSetPosition [_x, _y, _w, 0.07 * safezoneH];
    _header ctrlSetBackgroundColor [0.07, 0.075, 0.07, 1];
    _header ctrlSetText format ["%1  //  %2", _profile getOrDefault ["briefing", "FIELD OPERATING PROCEDURE"], _disp getVariable ["Waldo_MG_Help_Name", "EQUIPMENT"]];
    _header ctrlSetTextColor [0.94, 0.92, 0.82, 1];
    _header ctrlSetFontHeight (0.030 * safezoneH * _textScale);
    _header ctrlCommit 0;
    _created pushBack _header;

    private _accent = _disp ctrlCreate ["RscText", -1];
    _accent ctrlSetPosition [_x, _y + 0.067 * safezoneH, _w, 0.005 * safezoneH];
    _accent ctrlSetBackgroundColor (_profile getOrDefault ["accent", [0.82, 0.58, 0.18, 1]]);
    _accent ctrlCommit 0;
    _created pushBack _accent;

    private _text = _disp ctrlCreate ["RscStructuredText", -1];
    _text ctrlSetPosition [_x + 0.03 * safezoneW, _y + 0.095 * safezoneH, _w - 0.06 * safezoneW, 0.25 * safezoneH];
    _text ctrlSetStructuredText parseText format [
        "<t size='%5'><t color='#E6C15A' size='1.15'>OPERATION</t><br/><t color='#EEE9D8'>%1</t><br/><br/>" +
        "<t color='#E6C15A' size='1.15'>CONTROLS</t><br/><t color='#EEE9D8'>%2</t><br/><br/>" +
        "<t color='#E6C15A' size='1.15'>PROCEDURE NOTE</t><br/><t color='#EEE9D8'>%3</t><br/><br/>" +
        "<t color='#F2BE55'>%4</t></t>",
        _disp getVariable ["Waldo_MG_Help_Objective", ""],
        _disp getVariable ["Waldo_MG_Help_Controls", ""],
        _disp getVariable ["Waldo_MG_Help_Hint", ""],
        _profile getOrDefault ["abortText", "ABORTING COUNTS AS A FAILED PROCEDURE"],
        _textScale
    ];
    _text ctrlCommit 0;
    _created pushBack _text;

    private _close = _disp ctrlCreate ["RscButtonMenu", -1];
    _close ctrlSetPosition [_x + _w - 0.20 * safezoneW, _y + _h - 0.07 * safezoneH, 0.17 * safezoneW, 0.048 * safezoneH];
    _close ctrlSetText "RETURN TO EQUIPMENT";
    _close ctrlCommit 0;
    _close ctrlAddEventHandler ["ButtonClick", {
        private _disp = ctrlParent (_this select 0);
        [_disp] call (_disp getVariable ["Waldo_MG_Help_Close", {}]);
    }];
    _created pushBack _close;

    _disp setVariable ["Waldo_MG_Help_ControlsCreated", _created];
    ctrlSetFocus _close;
}];

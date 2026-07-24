/* Adds an on-demand grid-aligned field-procedure card. */
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
private _button = _display ctrlCreate ["RscButtonMenu", -1];
_button ctrlSetPosition [_canvasX + (34.5 * _cellW), _canvasY + (0.18 * _cellH), 4.3 * _cellW, 0.72 * _cellH];
_button ctrlSetText "? HELP";
_button ctrlSetTooltip "Open the equipment operating procedure";
_button ctrlCommit 0;
_display setVariable ["Waldo_MG_Help_Close", {
    params ["_display"];
    private _controls = _display getVariable ["Waldo_MG_Help_ControlsCreated", []];
    _display setVariable ["Waldo_MG_Help_ControlsCreated", []];
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
    private _largeText = (_profile getOrDefault ["accessibility", createHashMap]) getOrDefault ["largeText", false];
    private _created = [];
    private _shade = _display ctrlCreate ["RscText", -1];
    _shade ctrlSetPosition [_canvasX, _canvasY, _canvasW, _canvasH];
    _shade ctrlSetBackgroundColor [0, 0, 0, 0.86];
    _shade ctrlCommit 0;
    _created pushBack _shade;
    private _panel = _display ctrlCreate ["RscText", -1];
    _panel ctrlSetPosition [_canvasX + (4 * _cellW), _canvasY + (3 * _cellH), 32 * _cellW, 19 * _cellH];
    _panel ctrlSetBackgroundColor [0.12, 0.115, 0.095, 0.998];
    _panel ctrlCommit 0;
    _created pushBack _panel;
    private _header = _display ctrlCreate ["RscText", -1];
    _header ctrlSetPosition [_canvasX + (5 * _cellW), _canvasY + (4 * _cellH), 30 * _cellW, 2 * _cellH];
    _header ctrlSetText format ["%1 // %2", _profile getOrDefault ["briefing", "FIELD PROCEDURE"], _display getVariable ["Waldo_MG_Help_Name", "EQUIPMENT"]];
    _header ctrlSetTextColor [0.94, 0.92, 0.82, 1];
    _header ctrlSetBackgroundColor [0.055, 0.06, 0.055, 1];
    _header ctrlSetFontHeight ((if (_largeText) then {0.92} else {0.78}) * _cellH);
    _header ctrlCommit 0;
    _created pushBack _header;
    private _text = _display ctrlCreate ["RscStructuredText", -1];
    _text ctrlSetPosition [_canvasX + (6 * _cellW), _canvasY + (6.7 * _cellH), 28 * _cellW, 11.5 * _cellH];
    _text ctrlSetStructuredText parseText format [
        "<t size='%5'><t color='#E6C15A'>OPERATION</t><br/>%1<br/><br/><t color='#E6C15A'>CONTROLS</t><br/>%2<br/><br/><t color='#E6C15A'>PROCEDURE NOTE</t><br/>%3<br/><br/><t color='#F2BE55'>[!] %4</t></t>",
        _display getVariable ["Waldo_MG_Help_Objective", ""],
        _display getVariable ["Waldo_MG_Help_Controls", ""],
        _display getVariable ["Waldo_MG_Help_Hint", ""],
        _profile getOrDefault ["abortText", "ABORTING COUNTS AS FAILURE"],
        if (_largeText) then {1.13} else {1}
    ];
    _text ctrlCommit 0;
    _created pushBack _text;
    private _close = _display ctrlCreate ["RscButtonMenu", -1];
    _close ctrlSetPosition [_canvasX + (25 * _cellW), _canvasY + (19.3 * _cellH), 9 * _cellW, 1.7 * _cellH];
    _close ctrlSetText "RETURN TO EQUIPMENT";
    _close ctrlCommit 0;
    _close ctrlAddEventHandler ["ButtonClick", {private _display = ctrlParent (_this select 0); [_display] call (_display getVariable ["Waldo_MG_Help_Close", {}]);}];
    _created pushBack _close;
    _display setVariable ["Waldo_MG_Help_ControlsCreated", _created];
    ctrlSetFocus _close;
}];

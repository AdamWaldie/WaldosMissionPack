/* Creates an integrated, grid-aligned pre-operation maintenance card. */
disableSerialization;
params [["_display", displayNull, [displayNull]]];
if (isNull _display) exitWith {};
private _profile = _display getVariable ["Waldo_IMG_Profile", createHashMap];
private _bounds = _display getVariable ["Waldo_IMG_Bounds", [safeZoneX, safeZoneY, safeZoneW, safeZoneH]];
_bounds params ["_canvasX", "_canvasY", "_canvasW", "_canvasH"];
private _cellW = _canvasW / 40;
private _cellH = _canvasH / 25;
private _access = _profile getOrDefault ["accessibility", createHashMap];
private _largeText = _access getOrDefault ["largeText", false];
private _briefingControls = _profile getOrDefault ["controls", ""];
if (_briefingControls == "") then {_briefingControls = _display getVariable ["Waldo_MG_Help_Controls", "Use the displayed controls."];};
private _controls = [];
// Arma control types do not share a dependable painter's order. Hide the
// equipment face while the modal card is open so structured text from the
// underlying procedure can never bleed through the card.
private _equipmentFaceControls = (_display getVariable ["Waldo_MG_UI_EquipmentControls", []]) apply {[_x, ctrlShown _x]};
{if (!isNull (_x select 0)) then {(_x select 0) ctrlShow false;};} forEach _equipmentFaceControls;
_display setVariable ["Waldo_IMG_BriefingHiddenControls", _equipmentFaceControls];
private _shade = _display ctrlCreate ["RscText", -1];
_shade ctrlSetPosition [_canvasX, _canvasY, _canvasW, _canvasH];
_shade ctrlSetBackgroundColor [0, 0, 0, 0.86];
_shade ctrlCommit 0;
_controls pushBack _shade;
private _cardRect = if (_largeText) then {[3.25, 1.2, 33.5, 22.6]} else {[4.5, 1.5, 31, 22]};
_cardRect params ["_cardGX", "_cardGY", "_cardGW", "_cardGH"];
private _cardX = _canvasX + (_cardGX * _cellW);
private _cardY = _canvasY + (_cardGY * _cellH);
private _cardW = _cardGW * _cellW;
private _cardH = _cardGH * _cellH;
private _card = _display ctrlCreate ["RscText", -1];
_card ctrlSetPosition [_cardX, _cardY, _cardW, _cardH];
_card ctrlSetBackgroundColor [0.14, 0.13, 0.105, 0.998];
_card ctrlCommit 0;
_controls pushBack _card;
private _stripe = _display ctrlCreate ["RscText", -1];
_stripe ctrlSetPosition [_cardX, _cardY, _cardW, 0.22 * _cellH];
_stripe ctrlSetBackgroundColor (_profile getOrDefault ["accent", [0.82, 0.58, 0.18, 1]]);
_stripe ctrlCommit 0;
_controls pushBack _stripe;
private _left = _cardX + (1.5 * _cellW);
private _textWidth = _cardW - (3 * _cellW);
private _briefingText = [];
private _addLabel = {
    params ["_y", "_height", "_value", "_fontScale", "_colourHex", "_semantic"];
    // Structured text consistently paints above the procedural RscText card in
    // Arma. Mixing the two control types caused driver-dependent row loss.
    private _control = _display ctrlCreate ["RscStructuredText", -1];
    _control ctrlSetPosition [_left, _cardY + (_y * _cellH), _textWidth, _height * _cellH];
    _control ctrlSetStructuredText parseText format ["<t size='%1' color='%2'>%3</t>", _fontScale, _colourHex, _value];
    _control ctrlCommit 0;
    private _fittedScale = _fontScale;
    while {ctrlTextHeight _control > ((_height * _cellH) * 0.90) && {_fittedScale > 0.68}} do {
        _fittedScale = _fittedScale - 0.06;
        _control ctrlSetStructuredText parseText format ["<t size='%1' color='%2'>%3</t>", _fittedScale, _colourHex, _value];
        _control ctrlCommit 0;
    };
    _control setVariable ["Waldo_MG_UI_SemanticLabel", _semantic];
    _control setVariable ["Waldo_MG_UI_GridRect", [_cardGX + 1.5, _cardGY + _y, _cardGW - 3, _height]];
    _control setVariable ["Waldo_MG_UI_ProtectedRegion", true];
    _controls pushBack _control;
    _briefingText pushBack _control;
    _control
};
private _addWrapped = {
    params ["_y", "_height", "_value", "_size", "_colourHex", "_semantic"];
    private _control = _display ctrlCreate ["RscStructuredText", -1];
    _control ctrlSetPosition [_left, _cardY + (_y * _cellH), _textWidth, _height * _cellH];
    _control ctrlSetStructuredText parseText format ["<t size='%1' color='%2'>%3</t>", _size, _colourHex, _value];
    _control ctrlCommit 0;
    private _fittedSize = _size;
    while {ctrlTextHeight _control > ((_height * _cellH) * 0.90) && {_fittedSize > 0.68}} do {
        _fittedSize = _fittedSize - 0.06;
        _control ctrlSetStructuredText parseText format ["<t size='%1' color='%2'>%3</t>", _fittedSize, _colourHex, _value];
        _control ctrlCommit 0;
    };
    _control setVariable ["Waldo_MG_UI_SemanticLabel", _semantic];
    _control setVariable ["Waldo_MG_UI_GridRect", [_cardGX + 1.5, _cardGY + _y, _cardGW - 3, _height]];
    _control setVariable ["Waldo_MG_UI_ProtectedRegion", true];
    _controls pushBack _control;
    _briefingText pushBack _control;
    _control
};
[1.0, 1.75, _profile getOrDefault ["briefing", "FIELD OPERATING PROCEDURE"], 1.65, "#F2B847", "briefing heading"] call _addLabel;
[2.9, 1.25, format ["%1 // %2", _profile getOrDefault ["manufacturer", "FIELD SYSTEMS"], _profile getOrDefault ["model", "UNIT"]], 1.08, "#AEB09E", "manufacturer and model"] call _addLabel;
[4.35, 1.55, _profile getOrDefault ["title", _display getVariable ["Waldo_MG_Help_Name", "EQUIPMENT"]], 1.38, "#F0EBDD", "equipment operation title"] call _addLabel;
[6.15, 1.25, "OPERATION", 1.22, "#EBB242", "operation section label"] call _addLabel;
[7.55, 3.35, _profile getOrDefault ["objective", _display getVariable ["Waldo_MG_Help_Objective", "Complete the procedure."]], if (_largeText) then {1.34} else {1.18}, "#EEE9D8", "operation objective"] call _addWrapped;
[11.15, 1.25, "CONTROLS", 1.22, "#EBB242", "controls section label"] call _addLabel;
[12.55, 3.05, _briefingControls, if (_largeText) then {1.34} else {1.18}, "#EEE9D8", "operating controls"] call _addWrapped;
[15.95, 1.75, format ["[!] %1", _profile getOrDefault ["abortText", "ABORTING COUNTS AS A FAILED PROCEDURE"]], 1.08, "#F2B847", "abort consequence"] call _addLabel;
private _begin = _display ctrlCreate ["RscButton", -1];
_begin ctrlSetPosition [_cardX + _cardW - (11.5 * _cellW), _cardY + _cardH - (3 * _cellH), 10 * _cellW, 1.65 * _cellH];
_begin ctrlSetText (_profile getOrDefault ["activation", "BEGIN PROCEDURE"]);
_begin ctrlSetFontHeight ((0.72 * _cellH) max 0.016);
_begin ctrlSetTextColor [0.96, 0.96, 0.92, 1];
_begin ctrlSetBackgroundColor [0.04, 0.20, 0.34, 1];
_begin ctrlSetActiveColor [0.10, 0.48, 0.76, 1];
_begin ctrlSetTooltip "Start the procedure and its configured timer";
_begin ctrlCommit 0;
[_begin, 0.72 * _cellH, 0.40 * _cellH] call Waldo_fnc_MiniGameEquipmentFitText;
_begin setVariable ["Waldo_MG_UI_SemanticLabel", "begin operating procedure"];
_begin setVariable ["Waldo_MG_UI_GridRect", [_cardGX + _cardGW - 11.5, _cardGY + _cardGH - 3, 10, 1.65]];
_begin setVariable ["Waldo_MG_UI_ProtectedRegion", true];
_controls pushBack _begin;
private _shellControls = _display getVariable ["Waldo_MG_UI_ShellControls", []];
_shellControls append _controls;
_display setVariable ["Waldo_MG_UI_ShellControls", _shellControls];
private _equipmentControls = _display getVariable ["Waldo_MG_UI_EquipmentControls", []];
_equipmentControls append _briefingText;
_equipmentControls pushBack _begin;
_display setVariable ["Waldo_MG_UI_EquipmentControls", _equipmentControls];
_display setVariable ["Waldo_IMG_BriefingControls", _controls];
_display setVariable ["Waldo_IMG_BriefingBegin", _begin];
[_display] call Waldo_fnc_MiniGameApplyAccessibility;
_display setVariable ["Waldo_IMG_BriefingActivate", {
    params [["_begin", controlNull, [controlNull]]];
    if (isNull _begin) exitWith {};
    private _display = ctrlParent _begin;
    if (isNull _display || {_display getVariable ["Waldo_IMG_Started", false]}) exitWith {};
    private _controls = _display getVariable ["Waldo_IMG_BriefingControls", []];
    private _equipmentFaceControls = _display getVariable ["Waldo_IMG_BriefingHiddenControls", []];
    _display setVariable ["Waldo_IMG_BriefingControls", []];
    _display setVariable ["Waldo_IMG_BriefingHiddenControls", []];
    _display setVariable ["Waldo_IMG_Started", true];
    private _shellControls = _display getVariable ["Waldo_MG_UI_ShellControls", []];
    _shellControls = _shellControls select {!(_x in _controls)};
    _display setVariable ["Waldo_MG_UI_ShellControls", _shellControls];
    {
        _x params ["_control", "_wasShown"];
        if (!isNull _control) then {_control ctrlShow _wasShown;};
    } forEach _equipmentFaceControls;
    private _profile = _display getVariable ["Waldo_IMG_Profile", createHashMap];
    if ((_profile getOrDefault ["soundProfile", "equipment"]) != "silent") then {playSound "FD_Start_F";};
    private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then {
        _status ctrlSetText (_profile getOrDefault ["statusText", "[ACTIVE] FOLLOW THE OPERATING PROCEDURE"]);
    };
    [_controls] spawn {
        params ["_controls"];
        uiSleep 0;
        {if (!isNull _x) then {ctrlDelete _x;};} forEach _controls;
    };
    [_display] spawn {
        params ["_display"];
        uiSleep 0.12;
        if (!isNull _display) then {[_display, true] call Waldo_fnc_MiniGameEquipmentValidateDisplay;};
    };
}];
_begin ctrlAddEventHandler ["ButtonClick", {
    params ["_begin"];
    [_begin] call ((ctrlParent _begin) getVariable ["Waldo_IMG_BriefingActivate", {}]);
}];
ctrlSetFocus _begin;

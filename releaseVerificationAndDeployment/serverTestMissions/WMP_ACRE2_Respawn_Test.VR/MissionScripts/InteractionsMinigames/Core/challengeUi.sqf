/*
 * Author: WaldoTheWarfighter
 * Arma-native field-equipment display shared by every interaction procedure.
 *
 * The visible work area is a clipped 40 x 25 local grid. Challenge implementations
 * create controls through MiniGameEquipmentCreateControl and never perform safe-zone
 * arithmetic themselves. The shell owns input capture, timing, cleanup, abort and
 * exactly-once resolution.
 *
 * Arguments: title, objective, time limit, resolution callback, content height, input hint and help hint.
 * Return Value: DISPLAY - the created procedure display, or displayNull when unavailable.
 *
 * Example: ["FIELD EQUIPMENT", "Complete the procedure", 60, _resolve] call Waldo_fnc_MiniGameChallengeUi;
 * Current callers: all ten interaction-equipment procedure openers.
 */
disableSerialization;
params [
    ["_title", "FIELD EQUIPMENT", [""]],
    ["_objective", "Complete the operating procedure.", [""]],
    ["_timeLimit", 0, [0]],
    ["_resolve", {}, [{}]],
    ["_contentHeight", 0.48, [0]],
    ["_inputHint", "Mouse: operate equipment", [""]],
    ["_hint", "Follow the instrument labels and status display.", [""]]
];

if (!hasInterface) exitWith {
    [false, ["FAILURE", "NO INTERFACE"]] call _resolve;
    displayNull
};
private _active = uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
if (!isNull _active) exitWith {
    [false, ["FAILURE", "ANOTHER PROCEDURE IS ACTIVE"]] call _resolve;
    displayNull
};
private _parent = findDisplay 46;
if (isNull _parent) exitWith {
    [false, ["FAILURE", "MAIN DISPLAY UNAVAILABLE"]] call _resolve;
    displayNull
};

private _upperTitle = toUpper _title;
private _fallbackId = if (_upperTitle find "REPAIR" >= 0 || {_upperTitle find "MAINTENANCE" >= 0}) then {"repair"} else {
    if (_upperTitle find "RADIO" >= 0 || {_upperTitle find "SIGNAL" >= 0 || {_upperTitle find "COMMUNICATION" >= 0}}) then {"radiotune"} else {
        if (_upperTitle find "PRESSURE" >= 0 || {_upperTitle find "MANIFOLD" >= 0}) then {"pressure"} else {
            if (_upperTitle find "UPLINK" >= 0 || {_upperTitle find "COMMAND" >= 0}) then {"commandinput"} else {
            if (_upperTitle find "SEQUENCE" >= 0 || {_upperTitle find "CONSOLE" >= 0}) then {"sequence"} else {
                if (_upperTitle find "MINE" >= 0 || {_upperTitle find "TRIGGER" >= 0}) then {"minesweeper"} else {
                    if (_upperTitle find "KEY" >= 0 || {_upperTitle find "ACCESS" >= 0}) then {"keypad"} else {
                        if (_upperTitle find "LOCK" >= 0 || {_upperTitle find "CYLINDER" >= 0}) then {"lockpick"} else {
                            if (_upperTitle find "CIRCUIT" >= 0 || {_upperTitle find "BREAKER" >= 0}) then {"circuit"} else {"wirecut"};
                        };
                    };
                };
            };
            };
        };
    };
};
private _profile = missionNamespace getVariable ["Waldo_IMG_ActiveProfile", [_fallbackId, []] call Waldo_fnc_MiniGameEquipmentProfile];
private _access = _profile getOrDefault ["accessibility", [] call Waldo_fnc_MiniGameAccessibility];
if (_profile getOrDefault ["customTitle", false]) then {_title = _profile getOrDefault ["title", _title];} else {_profile set ["title", _title];};
_objective = _profile getOrDefault ["objective", _objective];
private _profileControls = _profile getOrDefault ["controls", ""];
if (_profileControls != "") then {_inputHint = _profileControls;};
private _profileHint = _profile getOrDefault ["hint", ""];
if (_profileHint != "") then {_hint = _profileHint;};

private _display = _parent createDisplay "RscDisplayEmpty";
if (isNull _display) exitWith {
    [false, ["FAILURE", "DISPLAY CREATION FAILED"]] call _resolve;
    displayNull
};
_display setVariable ["Waldo_UI_ThemedDisplay", true];
_display setVariable ["Waldo_MG_UI_RequestedContentHeight", _contentHeight];
uiNamespace setVariable ["Waldo_MG_ActiveChallengeDisplay", _display];

// Arma's normalized X and Y coordinates have different physical scales. Do not
// force the numeric 40:25 grid ratio into screen coordinates: doing so collapses
// the available height on widescreen displays. Instead, map the equipment-local
// grid independently into one visibly padded safe card.
private _viewportX = safeZoneX;
private _viewportY = safeZoneY;
private _viewportRight = safeZoneX + safeZoneW;
private _viewportBottom = safeZoneY + safeZoneH;
private _viewportW = (0.01 max (_viewportRight - _viewportX));
private _viewportH = (0.01 max (_viewportBottom - _viewportY));
private _gridWidthAbsolute = _viewportW * 0.92;
private _gridHeightAbsolute = _viewportH * 0.90;
private _canvasX = _viewportX + (_viewportW * 0.04);
private _canvasY = _viewportY + (_viewportH * 0.05);
private _cellW = _gridWidthAbsolute / 40;
private _cellH = _gridHeightAbsolute / 25;
private _contentX = _canvasX + (1.5 * _cellW);
private _contentY = _canvasY + (5.75 * _cellH);
private _contentW = 37 * _cellW;
private _contentH = 15.95 * _cellH;
private _textScale = if (_access getOrDefault ["largeText", false]) then {1.08} else {1};
private _accent = _profile getOrDefault ["accent", [0.82, 0.58, 0.18, 1]];
private _casing = _profile getOrDefault ["casing", [0.16, 0.17, 0.15, 1]];
private _theme = _profile getOrDefault ["uiTheme", [] call Waldo_fnc_UiTheme];

_display setVariable ["Waldo_MG_UI_Resolve", _resolve];
_display setVariable ["Waldo_MG_UI_Done", false];
_display setVariable ["Waldo_MG_UI_Content", [_contentX, _contentY, _contentW, _contentH]];
_display setVariable ["Waldo_MG_UI_GridCell", [_contentW / 40, _contentH / 25]];
_display setVariable ["Waldo_MG_UI_EquipmentControls", []];
_display setVariable ["Waldo_MG_UI_DisplayHandlers", []];
_display setVariable ["Waldo_MG_UI_Workers", []];
_display setVariable ["Waldo_MG_UI_DragControl", controlNull];
_display setVariable ["Waldo_IMG_Profile", _profile];
_display setVariable ["Waldo_IMG_AbortPending", false];
_display setVariable ["Waldo_IMG_Started", false];
_display setVariable ["Waldo_IMG_Bounds", [_canvasX, _canvasY, _gridWidthAbsolute, _gridHeightAbsolute]];

private _shade = _display ctrlCreate ["RscText", -1];
_shade ctrlSetPosition [_viewportX, _viewportY, _viewportW, _viewportH];
_shade ctrlSetBackgroundColor (_theme getOrDefault ["shade", [0, 0, 0, 0.72]]);
_shade ctrlCommit 0;
private _shadow = _display ctrlCreate ["RscText", -1];
_shadow ctrlSetPosition [_canvasX - (0.35 * _cellW), _canvasY - (0.35 * _cellH), _gridWidthAbsolute + (0.7 * _cellW), _gridHeightAbsolute + (0.7 * _cellH)];
_shadow ctrlSetBackgroundColor [0, 0, 0, 0.82];
_shadow ctrlCommit 0;
private _case = _display ctrlCreate ["RscText", -1];
_case ctrlSetPosition [_canvasX, _canvasY, _gridWidthAbsolute, _gridHeightAbsolute];
_case ctrlSetBackgroundColor _casing;
_case ctrlCommit 0;
private _header = _display ctrlCreate ["RscText", -1];
_header ctrlSetPosition [_canvasX + (1.5 * _cellW), _canvasY + _cellH, 37 * _cellW, 2.4 * _cellH];
_header ctrlSetBackgroundColor (_theme getOrDefault ["panelAlt", [0.045, 0.05, 0.045, 0.99]]);
_header ctrlCommit 0;
private _accentBar = _display ctrlCreate ["RscText", -1];
_accentBar ctrlSetPosition [_canvasX + (1.5 * _cellW), _canvasY + (3.3 * _cellH), 37 * _cellW, 0.18 * _cellH];
_accentBar ctrlSetBackgroundColor _accent;
_accentBar ctrlCommit 0;
private _heading = _display ctrlCreate ["RscText", -1];
_heading ctrlSetPosition [_canvasX + (1.7 * _cellW), _canvasY + (1.15 * _cellH), 23 * _cellW, 1.1 * _cellH];
_heading ctrlSetText _title;
_heading ctrlSetTextColor (_theme getOrDefault ["text", [0.95, 0.93, 0.84, 1]]);
_heading ctrlSetFont (_theme getOrDefault ["fontBold", "RobotoCondensedBold"]);
_heading ctrlSetFontHeight (1.05 * _cellH * _textScale);
_heading ctrlCommit 0;
[_heading, 1.05 * _cellH * _textScale, 0.42 * _cellH] call Waldo_fnc_MiniGameEquipmentFitText;
private _maker = _display ctrlCreate ["RscText", -1];
_maker ctrlSetPosition [_canvasX + (1.75 * _cellW), _canvasY + (2.25 * _cellH), 24 * _cellW, 0.65 * _cellH];
_maker ctrlSetText format ["%1  //  %2", _profile getOrDefault ["manufacturer", "FIELD SYSTEMS"], _profile getOrDefault ["model", "UNIT"]];
_maker ctrlSetTextColor (_theme getOrDefault ["muted", [0.62, 0.64, 0.57, 1]]);
_maker ctrlSetFont (_theme getOrDefault ["font", "RobotoCondensed"]);
_maker ctrlSetFontHeight ((0.72 * _cellH * _textScale) max 0.016);
_maker ctrlCommit 0;
[_maker, (0.72 * _cellH * _textScale) max 0.016, 0.38 * _cellH] call Waldo_fnc_MiniGameEquipmentFitText;
private _timer = _display ctrlCreate ["RscText", -1];
_timer ctrlSetPosition [_canvasX + (29 * _cellW), _canvasY + (1.3 * _cellH), 8 * _cellW, 1.2 * _cellH];
_timer ctrlSetText (if (_timeLimit > 0) then {format ["TIME  %1", ceil _timeLimit]} else {"NO TIME LIMIT"});
_timer ctrlSetTextColor (_theme getOrDefault ["warning", [0.96, 0.78, 0.30, 1]]);
_timer ctrlSetFont (_theme getOrDefault ["fontBold", "RobotoCondensedBold"]);
_timer ctrlSetFontHeight (0.82 * _cellH);
_timer ctrlCommit 0;
[_timer, 0.82 * _cellH, 0.42 * _cellH] call Waldo_fnc_MiniGameEquipmentFitText;
_display setVariable ["Waldo_MG_UI_TimerCtrl", _timer];
private _objectiveControl = _display ctrlCreate ["RscStructuredText", -1];
_objectiveControl ctrlSetPosition [_canvasX + (2 * _cellW), _canvasY + (3.68 * _cellH), 36 * _cellW, 1.75 * _cellH];
private _objectiveTemplate = format ["<t align='center' font='%1' size='%%1' color='%2'>", _theme getOrDefault ["font", "RobotoCondensed"], _theme getOrDefault ["textHex", "#E8E5D8"]] + _objective + "</t>";
[_objectiveControl, _objectiveTemplate, 1.12 * _textScale, 0.62] call Waldo_fnc_MiniGameEquipmentFitStructuredText;

private _contentGroup = _display ctrlCreate ["RscControlsGroupNoScrollbars", -1];
_contentGroup ctrlSetPosition [_contentX, _contentY, _contentW, _contentH];
_contentGroup ctrlCommit 0;
_display setVariable ["Waldo_MG_UI_ContentGroup", _contentGroup];
private _contentBack = [_display, "RscText", [0, 0, 40, 25], "equipment work area"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_contentBack ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.025, 0.03, 0.027, 0.99]]);
private _texturePath = _profile getOrDefault ["texture", ""];
if (_texturePath != "") then {
    private _texture = [_display, "RscPicture", [0, 0, 40, 25], "optional casing texture"] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _texture ctrlSetText _texturePath;
    _texture ctrlSetTextColor [1, 1, 1, _profile getOrDefault ["textureOpacity", 0.14]];
};
private _status = [_display, "RscText", [1, 0.55, 38, 1.75], "procedure status"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_status ctrlSetText format ["[STANDBY]  %1", _profile getOrDefault ["model", "FIELD UNIT"]];
_status ctrlSetTextColor (_theme getOrDefault ["warning", [0.96, 0.78, 0.30, 1]]);
_status ctrlSetFont (_theme getOrDefault ["fontBold", "RobotoCondensedBold"]);
_status ctrlSetFontHeight (((0.92 * (_contentH / 25) * _textScale) max 0.022) min 0.034);
_status ctrlSetBackgroundColor (_theme getOrDefault ["panelAlt", [0.04, 0.05, 0.045, 0.96]]);
[_status, ((0.92 * (_contentH / 25) * _textScale) max 0.022) min 0.034, 0.014] call Waldo_fnc_MiniGameEquipmentFitText;
_display setVariable ["Waldo_MG_UI_StatusCtrl", _status];

private _footer = _display ctrlCreate ["RscText", -1];
_footer ctrlSetPosition [_canvasX + (1.5 * _cellW), _canvasY + (22.05 * _cellH), 37 * _cellW, 1.75 * _cellH];
_footer ctrlSetBackgroundColor (_theme getOrDefault ["panelAlt", [0.045, 0.05, 0.045, 0.99]]);
_footer ctrlCommit 0;
private _footerHint = _display ctrlCreate ["RscText", -1];
_footerHint ctrlSetPosition [_canvasX + (1.85 * _cellW), _canvasY + (22.25 * _cellH), 24.8 * _cellW, 1.35 * _cellH];
_footerHint ctrlSetText _inputHint;
_footerHint ctrlSetTextColor (_theme getOrDefault ["text", [0.87, 0.85, 0.78, 1]]);
_footerHint ctrlSetFont (_theme getOrDefault ["font", "RobotoCondensed"]);
_footerHint ctrlSetFontHeight ((0.72 * _cellH * _textScale) max 0.017);
_footerHint ctrlCommit 0;
[_footerHint, (0.72 * _cellH * _textScale) max 0.017, 0.013] call Waldo_fnc_MiniGameEquipmentFitText;
private _footerAbort = _display ctrlCreate ["RscStructuredText", -1];
_footerAbort ctrlSetPosition [_canvasX + (27.0 * _cellW), _canvasY + (22.25 * _cellH), 11.1 * _cellW, 1.35 * _cellH];
[
    _footerAbort,
    format ["<t align='right' font='%1' color='%2' size='%%1'>ESC TWICE: ABORT [FAILURE]</t>", _theme getOrDefault ["font", "RobotoCondensed"], _theme getOrDefault ["warningHex", "#F2BD54"]],
    0.82 * _textScale,
    0.62
] call Waldo_fnc_MiniGameEquipmentFitStructuredText;
_display setVariable ["Waldo_MG_UI_ShellControls", [_shadow, _case, _header, _accentBar, _heading, _maker, _timer, _objectiveControl, _contentGroup, _footer, _footerHint, _footerAbort]];
_display setVariable ["Waldo_MG_UI_ResultCtrl", controlNull];

// Shared display-level pointer capture. Mouse movement remains active after leaving the source control.
private _moveId = _display displayAddEventHandler ["MouseMoving", {
    params ["_display"];
    private _control = _display getVariable ["Waldo_MG_UI_DragControl", controlNull];
    if (isNull _control) exitWith {false};
    getMousePosition params ["_mouseX", "_mouseY"];
    private _bounds = _display getVariable ["Waldo_MG_UI_Content", [0, 0, 1, 1]];
    private _local = [
        40 * ((_mouseX - (_bounds select 0)) / ((_bounds select 2) max 0.0001)),
        25 * ((_mouseY - (_bounds select 1)) / ((_bounds select 3) max 0.0001))
    ];
    [_display, _control, _local, "MOVE"] call (_control getVariable ["Waldo_MG_UI_DragCallback", {}]);
    true
}];
private _upId = _display displayAddEventHandler ["MouseButtonUp", {
    params ["_display", "_button"];
    if (_button != 0) exitWith {false};
    private _control = _display getVariable ["Waldo_MG_UI_DragControl", controlNull];
    if (isNull _control) exitWith {false};
    getMousePosition params ["_mouseX", "_mouseY"];
    private _bounds = _display getVariable ["Waldo_MG_UI_Content", [0, 0, 1, 1]];
    private _local = [40 * ((_mouseX - (_bounds select 0)) / ((_bounds select 2) max 0.0001)), 25 * ((_mouseY - (_bounds select 1)) / ((_bounds select 3) max 0.0001))];
    [_display, _control, _local, "END"] call (_control getVariable ["Waldo_MG_UI_DragCallback", {}]);
    _display setVariable ["Waldo_MG_UI_DragControl", controlNull];
    true
}];
private _keyId = _display displayAddEventHandler ["KeyDown", {
    params ["_display", "_key"];
    if (_key != 1) exitWith {false};
    if !(_display getVariable ["Waldo_IMG_AbortPending", false]) then {
        _display setVariable ["Waldo_IMG_AbortPending", true];
        private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
        if (!isNull _status) then {
            private _profile = _display getVariable ["Waldo_IMG_Profile", createHashMap];
            _status ctrlSetText format ["[!] PRESS ESC AGAIN: %1", _profile getOrDefault ["abortText", "ABORTING COUNTS AS FAILURE"]];
        };
        private _worker = [_display] spawn {
            params ["_display"];
            uiSleep 3;
            if (!isNull _display) then {_display setVariable ["Waldo_IMG_AbortPending", false];};
        };
        private _workers = _display getVariable ["Waldo_MG_UI_Workers", []];
        _workers pushBack _worker;
        _display setVariable ["Waldo_MG_UI_Workers", _workers];
    } else {
        [_display, false, "[X] PROCEDURE ABORTED"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
    };
    true
}];
_display setVariable ["Waldo_MG_UI_DisplayHandlers", [["MouseMoving", _moveId], ["MouseButtonUp", _upId], ["KeyDown", _keyId]]];

_display setVariable ["Waldo_MG_UI_Finish", {
    params ["_display", "_success", ["_reason", ""]];
    if (isNull _display || {_display getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
    _display setVariable ["Waldo_MG_UI_Done", true];
    [_display, "END"] call Waldo_fnc_MiniGameEquipmentCleanup;
    private _profile = _display getVariable ["Waldo_IMG_Profile", createHashMap];
    if ((_profile getOrDefault ["soundProfile", "equipment"]) != "silent") then {
        playSound (if (_success) then {"FD_Finish_F"} else {"FD_CP_Not_Clear_F"});
    };
    private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    private _resultText = if (_success) then {_profile getOrDefault ["successText", "PROCEDURE COMPLETE"]} else {_profile getOrDefault ["failureText", "PROCEDURE FAILED"]};
    if (!isNull _status) then {
        _status ctrlSetText format ["%1 %2", if (_success) then {"[OK]"} else {"[X]"}, if (_reason == "") then {_resultText} else {_reason}];
        _status ctrlSetTextColor (if (_success) then {_display getVariable ["Waldo_IMG_ColourOK", [0.35, 0.80, 0.45, 1]]} else {_display getVariable ["Waldo_IMG_ColourBad", [0.90, 0.32, 0.28, 1]]});
    };
    private _outcome = if (_success) then {"SUCCESS"} else {
        private _upper = toUpper _reason;
        if (_upper find "ABORT" >= 0) then {"ABORTED"} else {if (_upper find "TIME" >= 0 || {_upper find "EXPIRED" >= 0}) then {"TIMEOUT"} else {"FAILURE"}};
    };
    private _resolve = _display getVariable ["Waldo_MG_UI_Resolve", {}];
    private _delay = if (_display getVariable ["Waldo_IMG_ReducedMotion", false]) then {0.45} else {1.35};
    [_display, _resolve, _success, _outcome, _reason, _delay] spawn {
        params ["_display", "_resolve", "_success", "_outcome", "_reason", "_delay"];
        // Publish the authoritative outcome while the fixed equipment status
        // region is still visible. The result never jumps to a second overlay.
        [_success, [_outcome, _reason]] call _resolve;
        uiSleep _delay;
        uiNamespace setVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
        if (!isNull _display) then {_display closeDisplay 1;};
    };
}];

private _unloadId = _display displayAddEventHandler ["Unload", {
    params ["_display"];
    if !(_display getVariable ["Waldo_MG_UI_Done", false]) then {
        _display setVariable ["Waldo_MG_UI_Done", true];
        [_display, "CANCEL"] call Waldo_fnc_MiniGameEquipmentCleanup;
        private _resolve = _display getVariable ["Waldo_MG_UI_Resolve", {}];
        [false, ["ABANDONED", "DISPLAY LOST"]] call _resolve;
    };
    if ((uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull]) isEqualTo _display) then {
        uiNamespace setVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
    };
}];
private _handlers = _display getVariable ["Waldo_MG_UI_DisplayHandlers", []];
_handlers pushBack ["Unload", _unloadId];
_display setVariable ["Waldo_MG_UI_DisplayHandlers", _handlers];

if (_timeLimit > 0) then {
    private _timerWorker = [_display, _timeLimit] spawn {
        params ["_display", "_limit"];
        waitUntil {isNull _display || {_display getVariable ["Waldo_IMG_Started", false]}};
        if (isNull _display) exitWith {};
        private _deadline = time + _limit;
        while {!isNull _display && {!(_display getVariable ["Waldo_MG_UI_Done", false])}} do {
            private _remaining = (_deadline - time) max 0;
            private _control = _display getVariable ["Waldo_MG_UI_TimerCtrl", controlNull];
            if (!isNull _control) then {
                _control ctrlSetText format ["TIME  %1", ceil _remaining];
                if (_remaining <= (_limit * 0.25)) then {_control ctrlSetTextColor [1, 0.45, 0.60, 1];};
            };
            if (_remaining <= 0) exitWith {
                [_display, false, "[!] OPERATING WINDOW EXPIRED"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
            };
            uiSleep 0.08;
        };
    };
    private _workers = _display getVariable ["Waldo_MG_UI_Workers", []];
    _workers pushBack _timerWorker;
    _display setVariable ["Waldo_MG_UI_Workers", _workers];
};

[_display, _title, _objective, _inputHint, _hint] call Waldo_fnc_MiniGameChallengeHelp;
_display

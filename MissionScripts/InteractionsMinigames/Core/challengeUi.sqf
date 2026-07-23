/*
 * Author: Waldo
 * Creates the shared, responsive presentation shell used by interaction mini games. The shell
 * owns the global single-dialog guard, objective/status/timer chrome, explicit abort warning,
 * and exactly-once animated pass/fail resolution. Challenge scripts create only their controls
 * inside the content rectangle stored on the returned display.
 *
 * Arguments:
 * _title         - String - heading shown in the challenge header
 * _objective     - String - concise player instruction
 * _timeLimit     - Number - seconds before failure; 0 disables the clock
 * _resolve       - Code   - challenge callback invoked once with [_success]
 * _contentHeight - Number - content height as safezoneH fraction (default 0.48)
 * _inputHint     - String - controls shown in the footer (default "Use the mouse to interact")
 * _hint          - String - strategy shown in HOW TO PLAY (default: watch the status line)
 *
 * Return Value:
 * Display - shared challenge display, or displayNull when another challenge is active
 *
 * Example:
 * ["REPAIR", "Tighten every bolt.", 30, _resolve, 0.48, "Drag the wrench clockwise"]
 *     call Waldo_fnc_MiniGameChallengeUI;
 */

disableSerialization;

params [
    ["_title", "CHALLENGE", [""]],
    ["_objective", "Complete the interaction.", [""]],
    ["_timeLimit", 0, [0]],
    ["_resolve", {}, [{}]],
    ["_contentHeight", 0.48, [0]],
    ["_inputHint", "Use the mouse to interact", [""]],
    ["_hint", "Watch the status line after every input.", [""]]
];

private _fallbackId = if ((toUpper _title) find "REPAIR" >= 0 || {(toUpper _title) find "MAINTENANCE" >= 0}) then {"repair"} else {
    if ((toUpper _title) find "RADIO" >= 0 || {(toUpper _title) find "SIGNAL" >= 0 || {(toUpper _title) find "COMMUNICATION" >= 0}}) then {"radiotune"} else {
        if ((toUpper _title) find "PRESSURE" >= 0 || {(toUpper _title) find "MANIFOLD" >= 0}) then {"pressure"} else {
            if ((toUpper _title) find "SEQUENCE" >= 0 || {(toUpper _title) find "CONSOLE" >= 0}) then {"sequence"} else {"wirecut"};
        };
    };
};
private _profile = missionNamespace getVariable ["Waldo_IMG_ActiveProfile", [_fallbackId, []] call Waldo_fnc_MiniGameEquipmentProfile];
private _access = _profile getOrDefault ["accessibility", [] call Waldo_fnc_MiniGameAccessibility];
private _accentColour = _profile getOrDefault ["accent", [0.82, 0.58, 0.18, 1]];
private _casingColour = _profile getOrDefault ["casing", [0.16, 0.17, 0.15, 1]];
private _textScale = if (_access getOrDefault ["largeText", false]) then {1.14} else {1};
if (_profile getOrDefault ["customTitle", false]) then {
    _title = _profile getOrDefault ["title", _title];
} else {
    _profile set ["title", _title];
};
_objective = _profile getOrDefault ["objective", _objective];
private _profileControls = _profile getOrDefault ["controls", ""];
if (_profileControls != "") then {_inputHint = _profileControls;};
private _profileHint = _profile getOrDefault ["hint", ""];
if (_profileHint != "") then {_hint = _profileHint;};

if (!hasInterface) exitWith {
    [false] call _resolve;
    displayNull
};

private _active = missionNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
if (!isNull _active) exitWith {
    [false] call _resolve;
    displayNull
};

private _parent = findDisplay 46;
if (isNull _parent) exitWith {
    [false] call _resolve;
    displayNull
};

private _display = _parent createDisplay "RscDisplayEmpty";
if (isNull _display) exitWith {
    [false] call _resolve;
    displayNull
};

missionNamespace setVariable ["Waldo_MG_ActiveChallengeDisplay", _display];
_display displayAddEventHandler ["Unload", {
    params ["_disp"];
    if ((missionNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull]) isEqualTo _disp) then {
        missionNamespace setVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
    };
}];

private _panelW = (0.64 * safezoneW) min (0.92 * safezoneH);
private _headerH = 0.075 * safezoneH;
private _objectiveH = 0.065 * safezoneH;
private _footerH = 0.055 * safezoneH;
private _panelH = _headerH + _objectiveH + (_contentHeight * safezoneH) + _footerH;
private _panelX = safezoneX + (safezoneW - _panelW) / 2;
private _panelY = safezoneY + (safezoneH - _panelH) / 2;
private _contentX = _panelX + 0.018 * safezoneW;
private _contentY = _panelY + _headerH + _objectiveH;
private _contentW = _panelW - 0.036 * safezoneW;
private _contentH = _contentHeight * safezoneH;

_display setVariable ["Waldo_MG_UI_Resolve", _resolve];
_display setVariable ["Waldo_MG_UI_Done", false];
_display setVariable ["Waldo_MG_UI_Content", [_contentX, _contentY, _contentW, _contentH]];
_display setVariable ["Waldo_IMG_Profile", _profile];
_display setVariable ["Waldo_IMG_AbortPending", false];
_display setVariable ["Waldo_IMG_Started", false];
_display setVariable ["Waldo_IMG_Bounds", [_panelX, _panelY, _panelW, _panelH]];

private _shade = _display ctrlCreate ["RscText", -1];
_shade ctrlSetPosition [safezoneX, safezoneY, safezoneW, safezoneH];
_shade ctrlSetBackgroundColor [0, 0, 0, 0.62];
_shade ctrlCommit 0;

private _shadow = _display ctrlCreate ["RscText", -1];
_shadow ctrlSetPosition [_panelX - 0.008 * safezoneW, _panelY - 0.008 * safezoneH, _panelW + 0.016 * safezoneW, _panelH + 0.016 * safezoneH];
_shadow ctrlSetBackgroundColor [0, 0, 0, 0.78];
_shadow ctrlCommit 0;

private _panel = _display ctrlCreate ["RscText", -1];
_panel ctrlSetPosition [_panelX, _panelY, _panelW, _panelH];
_panel ctrlSetBackgroundColor _casingColour;
_panel ctrlCommit 0;

private _header = _display ctrlCreate ["RscText", -1];
_header ctrlSetPosition [_panelX, _panelY, _panelW, _headerH];
_header ctrlSetBackgroundColor [0.075, 0.08, 0.075, 0.99];
_header ctrlCommit 0;

private _accent = _display ctrlCreate ["RscText", -1];
_accent ctrlSetPosition [_panelX, _panelY + _headerH - 0.005 * safezoneH, _panelW, 0.005 * safezoneH];
_accent ctrlSetBackgroundColor _accentColour;
_accent ctrlCommit 0;

private _heading = _display ctrlCreate ["RscText", -1];
_heading ctrlSetPosition [_panelX + 0.02 * safezoneW, _panelY + 0.008 * safezoneH, _panelW * 0.68, _headerH - 0.014 * safezoneH];
_heading ctrlSetText _title;
_heading ctrlSetTextColor [0.94, 0.92, 0.82, 1];
_heading ctrlSetFontHeight (0.034 * safezoneH * _textScale);
_heading ctrlCommit 0;

private _timer = _display ctrlCreate ["RscText", -1];
_timer ctrlSetPosition [_panelX + _panelW - 0.19 * safezoneW, _panelY + 0.012 * safezoneH, 0.17 * safezoneW, 0.04 * safezoneH];
_timer ctrlSetText if (_timeLimit > 0) then {format ["TIME  %1", ceil _timeLimit]} else {"NO TIME LIMIT"};
_timer ctrlSetTextColor [0.94, 0.78, 0.30, 1];
_timer ctrlSetFontHeight (0.024 * safezoneH);
_timer ctrlCommit 0;
_display setVariable ["Waldo_MG_UI_TimerCtrl", _timer];

private _objectiveCtrl = _display ctrlCreate ["RscStructuredText", -1];
_objectiveCtrl ctrlSetPosition [_panelX + 0.02 * safezoneW, _panelY + _headerH + 0.008 * safezoneH, _panelW - 0.04 * safezoneW, _objectiveH - 0.012 * safezoneH];
_objectiveCtrl ctrlSetStructuredText parseText format ["<t align='center' size='%2' color='#E8E5D8'>%1</t>", _objective, 1.05 * _textScale];
_objectiveCtrl ctrlCommit 0;

private _content = _display ctrlCreate ["RscText", -1];
_content ctrlSetPosition [_contentX, _contentY, _contentW, _contentH];
_content ctrlSetBackgroundColor [0.035, 0.04, 0.038, 0.97];
_content ctrlCommit 0;
[_display, [_contentX, _contentY, _contentW, _contentH]] call Waldo_fnc_MiniGameEquipmentDecorate;
private _texturePath = _profile getOrDefault ["texture", ""];
if (_texturePath != "") then {
    private _texture = _display ctrlCreate ["RscPicture", -1];
    _texture ctrlSetPosition [_contentX, _contentY, _contentW, _contentH];
    _texture ctrlSetText _texturePath;
    _texture ctrlSetTextColor [1, 1, 1, _profile getOrDefault ["textureOpacity", 0.18]];
    _texture ctrlCommit 0;
};

private _status = _display ctrlCreate ["RscText", -1];
_status ctrlSetPosition [_contentX + 0.01 * safezoneW, _contentY + 0.008 * safezoneH, _contentW - 0.02 * safezoneW, 0.036 * safezoneH];
_status ctrlSetText format ["[STANDBY]  %1", _profile getOrDefault ["model", "FIELD UNIT"]];
_status ctrlSetTextColor [0.94, 0.78, 0.30, 1];
_status ctrlSetFontHeight (0.022 * safezoneH);
_status ctrlCommit 0;
_display setVariable ["Waldo_MG_UI_StatusCtrl", _status];

private _footer = _display ctrlCreate ["RscStructuredText", -1];
_footer ctrlSetPosition [_panelX + 0.02 * safezoneW, _contentY + _contentH + 0.007 * safezoneH, _panelW - 0.04 * safezoneW, _footerH - 0.01 * safezoneH];
_footer ctrlSetStructuredText parseText format [
    "<t align='left' color='#DDD8C8'>%1</t><t align='right' color='#F2BE55'>ESC: REQUEST ABORT  [FAILURE]</t>",
    _inputHint
];
_footer ctrlCommit 0;

private _result = _display ctrlCreate ["RscText", -1];
_result ctrlSetPosition [_contentX, _contentY + (_contentH - 0.09 * safezoneH) / 2, _contentW, 0.09 * safezoneH];
_result ctrlSetBackgroundColor [0, 0, 0, 0];
_result ctrlSetText "";
_result ctrlSetFontHeight (0.042 * safezoneH);
_result ctrlShow false;
_result ctrlCommit 0;
_display setVariable ["Waldo_MG_UI_ResultCtrl", _result];

private _maker = _display ctrlCreate ["RscText", -1];
_maker ctrlSetPosition [_panelX + 0.02 * safezoneW, _panelY + _headerH - 0.027 * safezoneH, _panelW * 0.66, 0.018 * safezoneH];
_maker ctrlSetText format ["%1  //  %2", _profile getOrDefault ["manufacturer", "FIELD SYSTEMS"], _profile getOrDefault ["model", "UNIT"]];
_maker ctrlSetTextColor [0.62, 0.63, 0.56, 1];
_maker ctrlSetFontHeight (0.014 * safezoneH * _textScale);
_maker ctrlCommit 0;

_display setVariable ["Waldo_MG_UI_Finish", {
    params ["_disp", "_success", ["_reason", ""]];
    if (isNull _disp || {_disp getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
    _disp setVariable ["Waldo_MG_UI_Done", true];
    private _cueProfile = _disp getVariable ["Waldo_IMG_Profile", createHashMap];
    if ((_cueProfile getOrDefault ["soundProfile", "equipment"]) != "silent") then {
        playSound (if (_success) then {"FD_Finish_F"} else {"FD_CP_Not_Clear_F"});
    };
    private _resultCtrl = _disp getVariable ["Waldo_MG_UI_ResultCtrl", controlNull];
    private _statusCtrl = _disp getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _statusCtrl) then {
        _statusCtrl ctrlSetText if (_reason == "") then {
            if (_success) then {format ["[OK]  %1", (_disp getVariable ["Waldo_IMG_Profile", createHashMap]) getOrDefault ["successText", "PROCEDURE COMPLETE"]]} else {format ["[X]  %1", (_disp getVariable ["Waldo_IMG_Profile", createHashMap]) getOrDefault ["failureText", "PROCEDURE FAILED"]]}
        } else {
            _reason
        };
        _statusCtrl ctrlSetTextColor if (_success) then {_disp getVariable ["Waldo_IMG_ColourOK", [0.35, 0.80, 0.45, 1]]} else {_disp getVariable ["Waldo_IMG_ColourBad", [0.90, 0.32, 0.28, 1]]};
    };
    if (!isNull _resultCtrl) then {
        private _resultText = if (_success) then {_cueProfile getOrDefault ["successText", "PROCEDURE COMPLETE"]} else {_cueProfile getOrDefault ["failureText", "PROCEDURE FAILED"]};
        private _caption = if (_disp getVariable ["Waldo_IMG_AudioCaptions", true] && {(_cueProfile getOrDefault ["soundProfile", "equipment"]) != "silent"}) then {if (_success) then {"  [AUDIO: CONFIRMATION TONE]"} else {"  [AUDIO: FAULT TONE]"}} else {""};
        _resultCtrl ctrlSetText format ["%1  %2%3", if (_success) then {"[OK]"} else {"[X]"}, _resultText, _caption];
        _resultCtrl ctrlSetTextColor if (_success) then {_disp getVariable ["Waldo_IMG_ColourOK", [0.55, 1, 0.65, 1]]} else {_disp getVariable ["Waldo_IMG_ColourBad", [1, 0.45, 0.40, 1]]};
        _resultCtrl ctrlSetBackgroundColor if (_success) then {[0.05, 0.20, 0.09, 0.96]} else {[0.24, 0.04, 0.04, 0.96]};
        _resultCtrl ctrlShow true;
        ctrlSetFocus _resultCtrl;
    };
    private _fnResolve = _disp getVariable ["Waldo_MG_UI_Resolve", {}];
    [{
        params ["_disp", "_resolve", "_success"];
        missionNamespace setVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
        if (!isNull _disp) then { _disp closeDisplay 1; };
        [_success] call _resolve;
    }, [_disp, _fnResolve, _success], if (_disp getVariable ["Waldo_IMG_ReducedMotion", false]) then {0.12} else {0.65}] call CBA_fnc_waitAndExecute;
}];

_display displayAddEventHandler ["KeyDown", {
    params ["_disp", "_key"];
    if (_key == 1) exitWith {
        if !(_disp getVariable ["Waldo_IMG_AbortPending", false]) then {
            _disp setVariable ["Waldo_IMG_AbortPending", true];
            private _status = _disp getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
            if (!isNull _status) then {
                private _profile = _disp getVariable ["Waldo_IMG_Profile", createHashMap];
                _status ctrlSetText format ["[!] PRESS ESC AGAIN: %1", _profile getOrDefault ["abortText", "ABORTING COUNTS AS A FAILED PROCEDURE"]];
            };
            [_disp] spawn {params ["_d"]; uiSleep 3; if (!isNull _d) then {_d setVariable ["Waldo_IMG_AbortPending", false];};};
        } else {
            private _finish = _disp getVariable ["Waldo_MG_UI_Finish", {}];
            [_disp, false, "[X] PROCEDURE ABORTED"] call _finish;
        };
        true
    };
    false
}];

if (_timeLimit > 0) then {
    [_display, _timeLimit] spawn {
        params ["_disp", "_limit"];
        waitUntil {isNull _disp || {_disp getVariable ["Waldo_IMG_Started", false]}};
        if (isNull _disp) exitWith {};
        private _deadline = time + _limit;
        while {!isNull _disp && {!(_disp getVariable ["Waldo_MG_UI_Done", false])}} do {
            private _remaining = (_deadline - time) max 0;
            private _timerCtrl = _disp getVariable ["Waldo_MG_UI_TimerCtrl", controlNull];
            if (!isNull _timerCtrl) then {
                _timerCtrl ctrlSetText format ["TIME  %1", ceil _remaining];
                if (_remaining <= (_limit * 0.25)) then {
                    _timerCtrl ctrlSetTextColor [1, 0.38, 0.32, 1];
                };
            };
            if (_remaining <= 0) exitWith {
                private _finish = _disp getVariable ["Waldo_MG_UI_Finish", {}];
                private _profile = _disp getVariable ["Waldo_IMG_Profile", createHashMap];
                [_disp, false, format ["[!] %1", _profile getOrDefault ["timeoutText", "OPERATING WINDOW EXPIRED"]]] call _finish;
            };
            sleep 0.08;
        };
    };
};

[_display, _title, _objective, _inputHint, _hint] call Waldo_fnc_MiniGameChallengeHelp;

_display

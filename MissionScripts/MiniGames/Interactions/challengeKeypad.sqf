/*
 * Author: Waldo
 * Keypad code-crack mini game (a built-in interaction challenge), a Mastermind-style deduction
 * puzzle. A hidden numeric code is generated; the player enters guesses and, after each, is told
 * how many digits are correct (right digit, right slot) and how many are misplaced (right digit,
 * wrong slot). Crack the code within the guess limit to win; run out of guesses, the clock, or
 * press Escape to fail. Ideal for safes, keypads, locked doors and arming panels.
 *
 * Challenge opener following the [_config, _resolve] contract; dispatched by
 * Waldo_fnc_MiniGameChallenge.
 *
 * Arguments:
 * _config  - Array - challenge config, all optional:
 *              0: _digits     - Number - code length, clamped 3..6 (default 4)
 *              1: _maxGuesses - Number - attempts allowed (default 6)
 *              2: _timeLimit  - Number - seconds on the clock, 0 = none (default 0)
 *              3: _title      - String - dialog heading (default "KEYPAD")
 * _resolve - Code  - called exactly once with [_success] (Boolean) when the challenge ends
 *
 * Return Value:
 * Nothing (result delivered asynchronously through _resolve)
 *
 * Example:
 * [[4, 6, 0, "SAFE"], { params ["_ok"]; systemChat str _ok; }] call Waldo_fnc_MiniGameKeypad;
 */

disableSerialization;

params [
    ["_config", []],
    ["_resolve", {}]
];

if (!hasInterface) exitWith { [false] call _resolve; };

_config params [
    ["_digits", 4],
    ["_maxGuesses", 6],
    ["_timeLimit", 0],
    ["_title", "KEYPAD"]
];

_digits = round _digits;
if (_digits < 3) then { _digits = 3; };
if (_digits > 6) then { _digits = 6; };
_maxGuesses = round _maxGuesses;
if (_maxGuesses < 1) then { _maxGuesses = 1; };

if (!isNull (missionNamespace getVariable ["Waldo_MG_KP_ActiveDisplay", displayNull])) exitWith {
    [false] call _resolve;
};

// Brand palette.
private _cPanel = [0.04, 0.05, 0.07, 0.94];
private _cHeader = [0.10, 0.13, 0.20, 1];
private _cAccent = [0.243, 0.463, 0.827, 1];
private _cAccentLt = [0.55, 0.72, 0.98, 1];
private _cText = [0.88, 0.90, 0.94, 1];
private _cKey = [0.16, 0.20, 0.28, 1];

// Hidden code (digits 0-9, repeats allowed).
private _code = [];
for "_i" from 0 to (_digits - 1) do { _code pushBack (floor (random 10)); };

private _parent = findDisplay 46;
if (isNull _parent) exitWith { [false] call _resolve; };
private _display = _parent createDisplay "RscDisplayEmpty";
if (isNull _display) exitWith { [false] call _resolve; };

missionNamespace setVariable ["Waldo_MG_KP_ActiveDisplay", _display];

_display setVariable ["Waldo_MG_KP_Code", _code];
_display setVariable ["Waldo_MG_KP_Digits", _digits];
_display setVariable ["Waldo_MG_KP_Entry", []];
_display setVariable ["Waldo_MG_KP_Remaining", _maxGuesses];
_display setVariable ["Waldo_MG_KP_Resolve", _resolve];
_display setVariable ["Waldo_MG_KP_Done", false];

_display setVariable ["Waldo_MG_KP_Finish", {
    params ["_disp", "_ok"];
    if (isNull _disp) exitWith {};
    if (_disp getVariable ["Waldo_MG_KP_Done", false]) exitWith {};
    _disp setVariable ["Waldo_MG_KP_Done", true];
    private _fnResolve = _disp getVariable ["Waldo_MG_KP_Resolve", {}];
    missionNamespace setVariable ["Waldo_MG_KP_ActiveDisplay", displayNull];
    [{
        params ["_disp", "_res", "_ok"];
        if (!isNull _disp) then { _disp closeDisplay 1; };
        [_ok] call _res;
    }, [_disp, _fnResolve, _ok], if (_ok) then {0} else {0.6}] call CBA_fnc_waitAndExecute;
}];

// Layout.
private _w = 0.34 * safezoneW;
private _h = 0.6 * safezoneH;
private _x = safezoneX + (safezoneW - _w) / 2;
private _y = safezoneY + (safezoneH - _h) / 2;

private _panel = _display ctrlCreate ["RscText", -1];
_panel ctrlSetPosition [_x - 0.01 * safezoneW, _y - 0.01 * safezoneH, _w + 0.02 * safezoneW, _h + 0.02 * safezoneH];
_panel ctrlSetBackgroundColor _cPanel;
_panel ctrlCommit 0;

private _accentBar = _display ctrlCreate ["RscText", -1];
_accentBar ctrlSetPosition [_x - 0.01 * safezoneW, _y - 0.01 * safezoneH, _w + 0.02 * safezoneW, 0.006 * safezoneH];
_accentBar ctrlSetBackgroundColor _cAccent;
_accentBar ctrlCommit 0;

private _heading = _display ctrlCreate ["RscText", -1];
_heading ctrlSetPosition [_x, _y, _w, 0.05 * safezoneH];
_heading ctrlSetText _title;
_heading ctrlSetTextColor _cAccentLt;
_heading ctrlSetBackgroundColor _cHeader;
_heading ctrlCommit 0;

private _entry = _display ctrlCreate ["RscText", -1];
_entry ctrlSetPosition [_x, _y + 0.06 * safezoneH, _w, 0.06 * safezoneH];
_entry ctrlSetBackgroundColor [0.02, 0.03, 0.04, 1];
_entry ctrlSetTextColor _cAccentLt;
_entry ctrlCommit 0;
_display setVariable ["Waldo_MG_KP_EntryCtrl", _entry];

private _status = _display ctrlCreate ["RscText", -1];
_status ctrlSetPosition [_x, _y + 0.125 * safezoneH, _w, 0.04 * safezoneH];
_status ctrlSetTextColor _cText;
_status ctrlSetText format ["Crack the %1-digit code.  Guesses: %2", _digits, _maxGuesses];
_status ctrlCommit 0;
_display setVariable ["Waldo_MG_KP_StatusCtrl", _status];

private _history = _display ctrlCreate ["RscStructuredText", -1];
_history ctrlSetPosition [_x, _y + 0.17 * safezoneH, _w, 0.19 * safezoneH];
_history ctrlSetBackgroundColor [0.02, 0.03, 0.04, 0.6];
_history ctrlSetStructuredText parseText "";
_history ctrlCommit 0;
_display setVariable ["Waldo_MG_KP_HistoryCtrl", _history];
_display setVariable ["Waldo_MG_KP_HistoryText", ""];

// Redraw the current entry line.
_display setVariable ["Waldo_MG_KP_Refresh", {
    params ["_disp"];
    private _entryCtrl = _disp getVariable ["Waldo_MG_KP_EntryCtrl", controlNull];
    private _digits = _disp getVariable ["Waldo_MG_KP_Digits", 4];
    private _e = _disp getVariable ["Waldo_MG_KP_Entry", []];
    private _txt = "";
    for "_i" from 0 to (_digits - 1) do {
        if (_i < (count _e)) then {
            _txt = _txt + format ["[ %1 ]", _e select _i];
        } else {
            _txt = _txt + "[ _ ]";
        };
    };
    if (!isNull _entryCtrl) then { _entryCtrl ctrlSetText _txt; };
}];
[_display] call (_display getVariable "Waldo_MG_KP_Refresh");

// Number pad + controls (0-9, Clear, Enter).
private _keyLabels = ["1","2","3","4","5","6","7","8","9","CLR","0","ENT"];
private _padTop = _y + 0.375 * safezoneH;
private _padW = (_w - 2 * 0.01 * safezoneW) / 3;
private _padH = 0.05 * safezoneH;
private _padGapX = 0.01 * safezoneW;
private _padGapY = 0.012 * safezoneH;
private _colX = _x;
{
    private _row = floor (_forEachIndex / 3);
    private _col = _forEachIndex mod 3;
    private _bx = _colX + _col * (_padW + _padGapX);
    private _by = _padTop + _row * (_padH + _padGapY);
    private _btn = _display ctrlCreate ["RscButton", -1];
    _btn ctrlSetPosition [_bx, _by, _padW, _padH];
    _btn ctrlSetText _x;
    _btn ctrlSetBackgroundColor _cKey;
    _btn ctrlSetTextColor _cText;
    _btn setVariable ["Waldo_MG_KP_Label", _x];
    _btn ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = ctrlParent _ctrl;
        if (isNull _disp || {_disp getVariable ["Waldo_MG_KP_Done", false]}) exitWith {};
        private _label = _ctrl getVariable ["Waldo_MG_KP_Label", ""];
        private _digits = _disp getVariable ["Waldo_MG_KP_Digits", 4];
        private _e = _disp getVariable ["Waldo_MG_KP_Entry", []];
        switch (_label) do {
            case "CLR": { _e = []; };
            case "ENT": {
                if ((count _e) == _digits) then {
                    [_disp] call (_disp getVariable "Waldo_MG_KP_Submit");
                    _e = _disp getVariable ["Waldo_MG_KP_Entry", []];
                };
            };
            default {
                if ((count _e) < _digits) then { _e pushBack (parseNumber _label); };
            };
        };
        _disp setVariable ["Waldo_MG_KP_Entry", _e];
        [_disp] call (_disp getVariable "Waldo_MG_KP_Refresh");
    }];
    _btn ctrlCommit 0;
} forEach _keyLabels;

// Evaluate a full entry.
_display setVariable ["Waldo_MG_KP_Submit", {
    params ["_disp"];
    private _code = _disp getVariable ["Waldo_MG_KP_Code", []];
    private _guess = _disp getVariable ["Waldo_MG_KP_Entry", []];
    private _digits = _disp getVariable ["Waldo_MG_KP_Digits", 4];
    if ((count _guess) != _digits) exitWith {};

    private _correct = 0;
    private _codeLeft = [];
    private _guessLeft = [];
    for "_i" from 0 to (_digits - 1) do {
        if ((_guess select _i) == (_code select _i)) then {
            _correct = _correct + 1;
        } else {
            _codeLeft pushBack (_code select _i);
            _guessLeft pushBack (_guess select _i);
        };
    };
    private _misplaced = 0;
    {
        private _idx = _codeLeft find _x;
        if (_idx >= 0) then {
            _misplaced = _misplaced + 1;
            _codeLeft set [_idx, -1];
        };
    } forEach _guessLeft;

    private _guessStr = "";
    { _guessStr = _guessStr + str _x; } forEach _guess;

    if (_correct == _digits) exitWith {
        private _fin = _disp getVariable ["Waldo_MG_KP_Finish", {}];
        [_disp, true] call _fin;
    };

    private _remaining = (_disp getVariable ["Waldo_MG_KP_Remaining", 1]) - 1;
    _disp setVariable ["Waldo_MG_KP_Remaining", _remaining];
    _disp setVariable ["Waldo_MG_KP_Entry", []];

    private _line = format ["<t color='#8CB8FA'>%1</t>   correct <t color='#59C46F'>%2</t>  misplaced <t color='#DBB833'>%3</t><br/>", _guessStr, _correct, _misplaced];
    private _hist = (_disp getVariable ["Waldo_MG_KP_HistoryText", "" ]) + _line;
    _disp setVariable ["Waldo_MG_KP_HistoryText", _hist];
    private _histCtrl = _disp getVariable ["Waldo_MG_KP_HistoryCtrl", controlNull];
    if (!isNull _histCtrl) then { _histCtrl ctrlSetStructuredText parseText _hist; };

    private _statusCtrl = _disp getVariable ["Waldo_MG_KP_StatusCtrl", controlNull];
    if (!isNull _statusCtrl) then {
        _statusCtrl ctrlSetText format ["Guesses remaining: %1", _remaining];
    };

    if (_remaining <= 0) then {
        private _fin = _disp getVariable ["Waldo_MG_KP_Finish", {}];
        [_disp, false] call _fin;
    };
}];

// Escape aborts (failure).
_display displayAddEventHandler ["KeyDown", {
    params ["_disp", "_key"];
    if (_key == 1) then {
        private _fin = _disp getVariable ["Waldo_MG_KP_Finish", {}];
        [_disp, false] call _fin;
        true
    } else {
        false
    };
}];

// Optional countdown.
if (_timeLimit > 0) then {
    private _deadline = time + _timeLimit;
    [_display, _deadline] spawn {
        params ["_disp", "_deadline"];
        while { !isNull _disp && {!(_disp getVariable ["Waldo_MG_KP_Done", false])} } do {
            if ((_deadline - time) <= 0) exitWith {
                private _fin = _disp getVariable ["Waldo_MG_KP_Finish", {}];
                [_disp, false] call _fin;
            };
            sleep 0.2;
        };
    };
};

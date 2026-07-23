/*
 * Author: Waldo
 * Circuit-wiring mini game (a built-in interaction challenge). Two columns of terminals are
 * shown; the right column is scrambled. Click a left terminal then its matching-colour terminal
 * on the right to splice that labelled wire and draw its visible path. Connect every wire to complete the circuit and win; too many
 * wrong splices, the clock running out, or Escape fails. Ideal for repair panels, junction
 * boxes, fuse boards and comms splicing.
 *
 * Challenge opener following the [_config, _resolve] contract; dispatched by
 * Waldo_fnc_MiniGameChallenge.
 *
 * Arguments:
 * _config  - Array - challenge config, all optional:
 *              0: _pairs        - Number - wires to connect, clamped 3..6 (default 4)
 *              1: _maxMistakes  - Number - wrong splices allowed (default 3)
 *              2: _timeLimit    - Number - seconds on the clock, 0 = none (default 0)
 *              3: _title        - String - dialog heading (default "CIRCUIT")
 * _resolve - Code  - called exactly once with [_success] (Boolean) when the challenge ends
 *
 * Return Value:
 * Nothing (result delivered asynchronously through _resolve)
 *
 * Example:
 * [[4, 3, 0, "REPAIR"], { params ["_ok"]; systemChat str _ok; }] call Waldo_fnc_MiniGameCircuit;
 */

disableSerialization;

params [
    ["_config", []],
    ["_resolve", {}]
];

if (!hasInterface) exitWith { [false] call _resolve; };

_config params [
    ["_pairs", 4],
    ["_maxMistakes", 3],
    ["_timeLimit", 0],
    ["_title", "BREAKER CABINET"]
];

_pairs = round _pairs;
if (_pairs < 3) then { _pairs = 3; };
if (_pairs > 6) then { _pairs = 6; };
_maxMistakes = round _maxMistakes;
if (_maxMistakes < 0) then { _maxMistakes = 0; };

if (!isNull (missionNamespace getVariable ["Waldo_MG_CR_ActiveDisplay", displayNull])) exitWith {
    [false] call _resolve;
};
if (!isNull (missionNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull])) exitWith {
    [false] call _resolve;
};

// Brand palette.
private _cPanel = [0.04, 0.05, 0.07, 0.94];
private _cHeader = [0.10, 0.13, 0.20, 1];
private _cAccent = [0.243, 0.463, 0.827, 1];
private _cAccentLt = [0.55, 0.72, 0.98, 1];
private _cText = [0.88, 0.90, 0.94, 1];

private _allColours = [
    ["RED",    [0.80, 0.24, 0.24, 1]],
    ["BLUE",   [0.26, 0.48, 0.86, 1]],
    ["YELLOW", [0.86, 0.76, 0.22, 1]],
    ["GREEN",  [0.28, 0.66, 0.34, 1]],
    ["WHITE",  [0.88, 0.88, 0.90, 1]],
    ["PURPLE", [0.62, 0.36, 0.78, 1]]
];
private _symbols = ["A", "B", "C", "D", "E", "F"];

// Left column = first _pairs colours in order; right column = the same set shuffled.
private _left = [];
for "_i" from 0 to (_pairs - 1) do { _left pushBack (_allColours select _i); };
private _right = +_left;
for "_i" from 0 to (_pairs - 1) do {
    private _j = floor (random _pairs);
    private _tmp = _right select _i;
    _right set [_i, _right select _j];
    _right set [_j, _tmp];
};

private _parent = findDisplay 46;
if (isNull _parent) exitWith { [false] call _resolve; };
private _display = _parent createDisplay "RscDisplayEmpty";
if (isNull _display) exitWith { [false] call _resolve; };

missionNamespace setVariable ["Waldo_MG_CR_ActiveDisplay", _display];
missionNamespace setVariable ["Waldo_MG_ActiveChallengeDisplay", _display];
[_display, "Select a labelled left terminal, then its matching right terminal", _title, "Connect every left terminal to the right terminal with the same label and colour.", "Labels make every pairing unambiguous. Select a new left terminal to change your choice."] call Waldo_fnc_MiniGameChallengeUILegacy;

private _leftDone = []; { _leftDone pushBack false; } forEach _left;
private _rightDone = []; { _rightDone pushBack false; } forEach _right;

_display setVariable ["Waldo_MG_CR_LeftColours", _left];
_display setVariable ["Waldo_MG_CR_RightColours", _right];
_display setVariable ["Waldo_MG_CR_LeftDone", _leftDone];
_display setVariable ["Waldo_MG_CR_RightDone", _rightDone];
_display setVariable ["Waldo_MG_CR_ActiveLeft", -1];
_display setVariable ["Waldo_MG_CR_Connected", 0];
_display setVariable ["Waldo_MG_CR_Total", _pairs];
_display setVariable ["Waldo_MG_CR_Mistakes", 0];
_display setVariable ["Waldo_MG_CR_MaxMistakes", _maxMistakes];
_display setVariable ["Waldo_MG_CR_Resolve", _resolve];
_display setVariable ["Waldo_MG_CR_Done", false];

_display setVariable ["Waldo_MG_CR_Finish", {
    params ["_disp", "_ok", ["_resultKey", ""]];
    if (isNull _disp) exitWith {};
    if (_disp getVariable ["Waldo_MG_CR_Done", false]) exitWith {};
    _disp setVariable ["Waldo_MG_CR_Done", true];
    [_disp, _ok, _resultKey] call (_disp getVariable ["Waldo_IMG_ShowResult", {}]);
    private _fnResolve = _disp getVariable ["Waldo_MG_CR_Resolve", {}];
    missionNamespace setVariable ["Waldo_MG_CR_ActiveDisplay", displayNull];
    [{
        params ["_disp", "_res", "_ok"];
        if (!isNull _disp) then { _disp closeDisplay 1; };
        [_ok] call _res;
    }, [_disp, _fnResolve, _ok], if (_disp getVariable ["Waldo_IMG_ReducedMotion", false]) then {0.12} else {if (_ok) then {0.45} else {0.5}}] call CBA_fnc_waitAndExecute;
}];

// Layout.
private _w = 0.4 * safezoneW;
private _rowH = 0.05 * safezoneH;
private _gap = 0.012 * safezoneH;
private _h = 0.16 * safezoneH + _pairs * (_rowH + _gap);
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

private _status = _display ctrlCreate ["RscText", -1];
_status ctrlSetPosition [_x, _y + 0.055 * safezoneH, _w, 0.04 * safezoneH];
_status ctrlSetTextColor _cText;
_status ctrlSetText format ["Splice matching wires.  Mistakes allowed: %1", _maxMistakes];
_status ctrlCommit 0;
_display setVariable ["Waldo_MG_CR_StatusCtrl", _status];

private _colW = 0.15 * safezoneW;
private _leftX = _x;
private _rightX = _x + _w - _colW;
private _top = _y + 0.11 * safezoneH;

private _leftBtns = [];
private _rightBtns = [];
for "_i" from 0 to (_pairs - 1) do {
    private _rowY = _top + _i * (_rowH + _gap);

    private _lb = _display ctrlCreate ["RscButton", -1];
    _lb ctrlSetPosition [_leftX, _rowY, _colW, _rowH];
    _lb ctrlSetText format ["[%1] %2", _symbols select _i, (_left select _i) select 0];
    _lb ctrlSetBackgroundColor ((_left select _i) select 1);
    _lb ctrlSetTextColor [0.05, 0.05, 0.06, 1];
    _lb setVariable ["Waldo_MG_CR_Side", "L"];
    _lb setVariable ["Waldo_MG_CR_Index", _i];
    _lb ctrlAddEventHandler ["ButtonClick", { _this call Waldo_MG_CR_onClick }];
    _lb ctrlCommit 0;
    _leftBtns pushBack _lb;

    private _rb = _display ctrlCreate ["RscButton", -1];
    _rb ctrlSetPosition [_rightX, _rowY, _colW, _rowH];
    private _rightSymbol = _symbols select (_left find (_right select _i));
    _rb ctrlSetText format ["[%1] %2", _rightSymbol, (_right select _i) select 0];
    _rb ctrlSetBackgroundColor ((_right select _i) select 1);
    _rb ctrlSetTextColor [0.05, 0.05, 0.06, 1];
    _rb setVariable ["Waldo_MG_CR_Side", "R"];
    _rb setVariable ["Waldo_MG_CR_Index", _i];
    _rb ctrlAddEventHandler ["ButtonClick", { _this call Waldo_MG_CR_onClick }];
    _rb ctrlCommit 0;
    _rightBtns pushBack _rb;
};
_display setVariable ["Waldo_MG_CR_LeftBtns", _leftBtns];
_display setVariable ["Waldo_MG_CR_RightBtns", _rightBtns];

// Shared click handler (defined as a global so both columns can bind to it by name).
Waldo_MG_CR_onClick = {
    params ["_ctrl"];
    private _disp = ctrlParent _ctrl;
    if (isNull _disp || {_disp getVariable ["Waldo_MG_CR_Done", false]}) exitWith {};
    private _side = _ctrl getVariable ["Waldo_MG_CR_Side", ""];
    private _idx = _ctrl getVariable ["Waldo_MG_CR_Index", -1];
    private _leftDone = _disp getVariable ["Waldo_MG_CR_LeftDone", []];
    private _rightDone = _disp getVariable ["Waldo_MG_CR_RightDone", []];
    private _leftBtns = _disp getVariable ["Waldo_MG_CR_LeftBtns", []];

    if (_side == "L") exitWith {
        if (_leftDone select _idx) exitWith {};
        // Highlight the newly selected left terminal, dim the rest.
        {
            if !(_leftDone select _forEachIndex) then {
                _x ctrlSetTextColor [0.05, 0.05, 0.06, 1];
            };
        } forEach _leftBtns;
        _ctrl ctrlSetTextColor [1, 1, 1, 1];
        _disp setVariable ["Waldo_MG_CR_ActiveLeft", _idx];
    };

    // Right terminal clicked.
    if (_rightDone select _idx) exitWith {};
    private _activeLeft = _disp getVariable ["Waldo_MG_CR_ActiveLeft", -1];
    if (_activeLeft < 0) exitWith {};

    private _left = _disp getVariable ["Waldo_MG_CR_LeftColours", []];
    private _right = _disp getVariable ["Waldo_MG_CR_RightColours", []];
    private _rightBtns = _disp getVariable ["Waldo_MG_CR_RightBtns", []];

    if (((_left select _activeLeft) select 0) == ((_right select _idx) select 0)) then {
        // Correct splice.
        private _leftPos = ctrlPosition (_leftBtns select _activeLeft);
        private _rightPos = ctrlPosition (_rightBtns select _idx);
        private _startX = (_leftPos select 0) + (_leftPos select 2);
        private _startY = (_leftPos select 1) + (_leftPos select 3) / 2;
        private _endX = _rightPos select 0;
        private _endY = (_rightPos select 1) + (_rightPos select 3) / 2;
        private _dx = _endX - _startX;
        private _dy = _endY - _startY;
        private _wireLine = _disp ctrlCreate ["RscText", -1];
        _wireLine ctrlSetPosition [_startX, _startY, sqrt (_dx * _dx + _dy * _dy), 0.006 * safezoneH];
        _wireLine ctrlSetBackgroundColor ((_left select _activeLeft) select 1);
        _wireLine ctrlSetAngle [-(_dy atan2 _dx), 0, 0.5];
        _wireLine ctrlCommit 0;
        _leftDone set [_activeLeft, true];
        _rightDone set [_idx, true];
        _disp setVariable ["Waldo_MG_CR_LeftDone", _leftDone];
        _disp setVariable ["Waldo_MG_CR_RightDone", _rightDone];
        (_leftBtns select _activeLeft) ctrlSetText "LINKED";
        (_leftBtns select _activeLeft) ctrlSetBackgroundColor [0.12, 0.14, 0.16, 1];
        (_leftBtns select _activeLeft) ctrlSetTextColor [0.35, 0.80, 0.45, 1];
        _ctrl ctrlSetText "LINKED";
        _ctrl ctrlSetBackgroundColor [0.12, 0.14, 0.16, 1];
        _ctrl ctrlSetTextColor [0.35, 0.80, 0.45, 1];
        _disp setVariable ["Waldo_MG_CR_ActiveLeft", -1];
        private _connected = (_disp getVariable ["Waldo_MG_CR_Connected", 0]) + 1;
        _disp setVariable ["Waldo_MG_CR_Connected", _connected];
        if (_connected >= (_disp getVariable ["Waldo_MG_CR_Total", 1])) then {
            private _fin = _disp getVariable ["Waldo_MG_CR_Finish", {}];
            [_disp, true] call _fin;
        };
    } else {
        // Wrong splice.
        private _mistakes = (_disp getVariable ["Waldo_MG_CR_Mistakes", 0]) + 1;
        _disp setVariable ["Waldo_MG_CR_Mistakes", _mistakes];
        private _max = _disp getVariable ["Waldo_MG_CR_MaxMistakes", 3];
        private _statusCtrl = _disp getVariable ["Waldo_MG_CR_StatusCtrl", controlNull];
        if (!isNull _statusCtrl) then {
            _statusCtrl ctrlSetText format ["Wrong wire!  Mistakes: %1 / %2", _mistakes, _max];
        };
        if (_mistakes > _max) then {
            private _fin = _disp getVariable ["Waldo_MG_CR_Finish", {}];
            [_disp, false] call _fin;
        };
    };
};

// Escape aborts (failure).
_display displayAddEventHandler ["KeyDown", {
    params ["_disp", "_key"];
    if (_key == 1) then {
        private _fin = _disp getVariable ["Waldo_MG_CR_Finish", {}];
        [_disp, _fin] call (_disp getVariable ["Waldo_IMG_RequestAbort", {}]);
        true
    } else {
        false
    };
}];

// Optional countdown.
if (_timeLimit > 0) then {
    [_display, _timeLimit] spawn {
        params ["_disp", "_timeLimit"];
        waitUntil {isNull _disp || {_disp getVariable ["Waldo_IMG_Started", false]}};
        if (isNull _disp) exitWith {};
        private _deadline = time + _timeLimit;
        while { !isNull _disp && {!(_disp getVariable ["Waldo_MG_CR_Done", false])} } do {
            if ((_deadline - time) <= 0) exitWith {
                private _fin = _disp getVariable ["Waldo_MG_CR_Finish", {}];
                [_disp, false, "timeoutText"] call _fin;
            };
            sleep 0.2;
        };
    };
};
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

/*
 * Author: Waldo
 * Minesweeper defusal/hacking mini game (a built-in interaction challenge). Opens a grid on
 * the calling player: reveal every safe cell to win; strike a mine, run out the clock or press
 * Escape to fail. The first reveal is safe, right-click flags suspected mines, numbers show how
 * many mines touch a cell, and empty cells flood-reveal their neighbours. The whole challenge runs locally on the actor
 * and reports one boolean through the provided resolve callback, so it can gate any outcome.
 *
 * This is a challenge opener following the [_config, _resolve] contract; it is dispatched by
 * Waldo_fnc_MiniGameChallenge and registered by Waldo_fnc_MiniGameRegisterChallenge.
 *
 * Arguments:
 * _config  - Array - challenge config, all optional:
 *              0: _size      - Number - grid width/height, clamped 4..8 (default 5)
 *              1: _mineCount - Number - mines on the grid (default 5)
 *              2: _timeLimit - Number - seconds on the clock, 0 = none (default 0)
 *              3: _title     - String - dialog heading (default "MINESWEEPER")
 * _resolve - Code  - called once with boolean success and typed outcome metadata
 *
 * Return Value:
 * Nothing (result delivered asynchronously through _resolve)
 *
 * Example:
 * [[5, 5, 0, "HACKING"], { params ["_ok"]; systemChat str _ok; }] call Waldo_fnc_MiniGameMinesweeper;
 */

disableSerialization;

params [
    ["_config", []],
    ["_resolve", {}]
];

if (!hasInterface) exitWith { [false] call _resolve; };

_config params [
    ["_size", 5],
    ["_mineCount", 5],
    ["_timeLimit", 0],
    ["_title", "TRIGGER ANALYSER"]
];

_size = round _size;
if (_size < 4) then { _size = 4; };
if (_size > 8) then { _size = 8; };

private _cells = _size * _size;
_mineCount = round _mineCount;
if (_mineCount < 1) then { _mineCount = 1; };
if (_mineCount > (_cells - 1)) then { _mineCount = _cells - 1; };

if (!isNull (missionNamespace getVariable ["Waldo_MG_MS_ActiveDisplay", displayNull])) exitWith {
    [false] call _resolve;
};
if (!isNull (missionNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull])) exitWith {
    [false] call _resolve;
};

// WMP brand palette (kept inline so the challenge runs without the table engine).
private _cPanel = [0.04, 0.05, 0.07, 0.94];
private _cHeader = [0.10, 0.13, 0.20, 1];
private _cAccent = [0.243, 0.463, 0.827, 1];
private _cAccentLt = [0.55, 0.72, 0.98, 1];
private _cText = [0.88, 0.90, 0.94, 1];
private _cCell = [0.16, 0.20, 0.28, 1];

// Lay the mines and count adjacency.
private _mines = [];
for "_i" from 0 to (_cells - 1) do { _mines pushBack false; };
private _placed = 0;
while { _placed < _mineCount } do {
    private _r = floor (random _cells);
    if !(_mines select _r) then {
        _mines set [_r, true];
        _placed = _placed + 1;
    };
};

private _adj = [];
for "_i" from 0 to (_cells - 1) do {
    private _row = floor (_i / _size);
    private _col = _i mod _size;
    private _count = 0;
    for "_dr" from -1 to 1 do {
        for "_dc" from -1 to 1 do {
            private _nr = _row + _dr;
            private _nc = _col + _dc;
            if (_nr >= 0 && {_nr < _size} && {_nc >= 0} && {_nc < _size}) then {
                private _ni = _nr * _size + _nc;
                if (_mines select _ni) then { _count = _count + 1; };
            };
        };
    };
    _adj pushBack _count;
};

private _revealed = [];
for "_i" from 0 to (_cells - 1) do { _revealed pushBack false; };

private _parent = findDisplay 46;
if (isNull _parent) exitWith { [false] call _resolve; };
private _display = _parent createDisplay "RscDisplayEmpty";
if (isNull _display) exitWith { [false] call _resolve; };

missionNamespace setVariable ["Waldo_MG_MS_ActiveDisplay", _display];
missionNamespace setVariable ["Waldo_MG_ActiveChallengeDisplay", _display];
[_display, "Left click: reveal    Right click: flag", _title, "Reveal every safe cell without opening a mine.", "The first reveal is always safe. Empty cells open nearby safe areas automatically."] call Waldo_fnc_MiniGameChallengeUILegacy;

_display setVariable ["Waldo_MG_MS_Size", _size];
_display setVariable ["Waldo_MG_MS_Mines", _mines];
_display setVariable ["Waldo_MG_MS_Adj", _adj];
_display setVariable ["Waldo_MG_MS_Revealed", _revealed];
_display setVariable ["Waldo_MG_MS_Resolve", _resolve];
_display setVariable ["Waldo_MG_MS_Done", false];
_display setVariable ["Waldo_MG_MS_FirstMove", true];
private _flagged = [];
for "_i" from 0 to (_cells - 1) do { _flagged pushBack false; };
_display setVariable ["Waldo_MG_MS_Flagged", _flagged];
_display setVariable ["Waldo_MG_MS_RebuildAdj", {
    params ["_disp"];
    private _size = _disp getVariable ["Waldo_MG_MS_Size", 5];
    private _mines = _disp getVariable ["Waldo_MG_MS_Mines", []];
    private _adj = [];
    for "_i" from 0 to ((count _mines) - 1) do {
        private _row = floor (_i / _size);
        private _col = _i mod _size;
        private _count = 0;
        for "_dr" from -1 to 1 do {
            for "_dc" from -1 to 1 do {
                private _nr = _row + _dr;
                private _nc = _col + _dc;
                if (_nr >= 0 && {_nr < _size} && {_nc >= 0} && {_nc < _size}) then {
                    if (_mines select (_nr * _size + _nc)) then { _count = _count + 1; };
                };
            };
        };
        _adj pushBack _count;
    };
    _disp setVariable ["Waldo_MG_MS_Adj", _adj];
}];

// Single-shot finisher.
_display setVariable ["Waldo_MG_MS_Finish", {
    params ["_disp", "_ok", ["_resultKey", ""]];
    if (isNull _disp) exitWith {};
    if (_disp getVariable ["Waldo_MG_MS_Done", false]) exitWith {};
    _disp setVariable ["Waldo_MG_MS_Done", true];
    [_disp, _ok, _resultKey] call (_disp getVariable ["Waldo_IMG_ShowResult", {}]);
    // On a loss, reveal the mines so the player sees the board.
    if (!_ok) then {
        private _mines = _disp getVariable ["Waldo_MG_MS_Mines", []];
        private _btns = _disp getVariable ["Waldo_MG_MS_Buttons", []];
        {
            if (_x && {_forEachIndex < (count _btns)}) then {
                (_btns select _forEachIndex) ctrlSetText "X";
                (_btns select _forEachIndex) ctrlSetBackgroundColor [0.80, 0.22, 0.20, 1];
            };
        } forEach _mines;
    };
    private _fnResolve = _disp getVariable ["Waldo_MG_MS_Resolve", {}];
    private _outcomeCode = if (_ok) then {"SUCCESS"} else {if (_resultKey == "timeoutText") then {"TIMEOUT"} else {if (_resultKey == "abortText") then {"ABORTED"} else {"FAILURE"};};};
    private _reason = if (_resultKey == "") then {""} else {(_disp getVariable ["Waldo_IMG_Profile", createHashMap]) getOrDefault [_resultKey, _resultKey]};
    missionNamespace setVariable ["Waldo_MG_MS_ActiveDisplay", displayNull];
    [{
        params ["_disp", "_res", "_ok", "_outcomeCode", "_reason"];
        if (!isNull _disp) then { _disp closeDisplay 1; };
        [_ok, [_outcomeCode, _reason]] call _res;
    }, [_disp, _fnResolve, _ok, _outcomeCode, _reason], if (_disp getVariable ["Waldo_IMG_ReducedMotion", false]) then {0.12} else {if (_ok) then {0.45} else {0.6}}] call CBA_fnc_waitAndExecute;
}];

// Flood-reveal routine (stored so the button handler can call it).
_display setVariable ["Waldo_MG_MS_Reveal", {
    params ["_disp", "_start"];
    private _size = _disp getVariable ["Waldo_MG_MS_Size", 5];
    private _mines = _disp getVariable ["Waldo_MG_MS_Mines", []];
    private _adj = _disp getVariable ["Waldo_MG_MS_Adj", []];
    private _rev = _disp getVariable ["Waldo_MG_MS_Revealed", []];
    private _btns = _disp getVariable ["Waldo_MG_MS_Buttons", []];
    private _numColours = [
        [0.55, 0.72, 0.98, 1], [0.35, 0.75, 0.45, 1], [0.85, 0.55, 0.30, 1],
        [0.86, 0.72, 0.20, 1], [0.80, 0.40, 0.75, 1], [0.60, 0.85, 0.90, 1],
        [0.88, 0.90, 0.94, 1], [0.88, 0.90, 0.94, 1]
    ];
    private _stack = [_start];
    while { count _stack > 0 } do {
        private _i = _stack deleteAt 0;
        if !(_rev select _i) then {
            _rev set [_i, true];
            private _n = _adj select _i;
            private _b = _btns select _i;
            _b ctrlSetBackgroundColor [0.09, 0.10, 0.12, 1];
            if (_n > 0) then {
                _b ctrlSetText str _n;
                _b ctrlSetTextColor (_numColours select ((_n - 1) min 7));
            } else {
                _b ctrlSetText "";
                private _row = floor (_i / _size);
                private _col = _i mod _size;
                for "_dr" from -1 to 1 do {
                    for "_dc" from -1 to 1 do {
                        private _nr = _row + _dr;
                        private _nc = _col + _dc;
                        if (_nr >= 0 && {_nr < _size} && {_nc >= 0} && {_nc < _size}) then {
                            private _ni = _nr * _size + _nc;
                            if (!(_rev select _ni) && {!(_mines select _ni)}) then {
                                _stack pushBack _ni;
                            };
                        };
                    };
                };
            };
        };
    };
    _disp setVariable ["Waldo_MG_MS_Revealed", _rev];

    // Win when every safe cell is revealed.
    private _safe = 0;
    { if (!_x) then { _safe = _safe + 1; }; } forEach _mines;
    private _revCount = 0;
    { if (_x) then { _revCount = _revCount + 1; }; } forEach _rev;
    if (_revCount >= _safe) then {
        private _fin = _disp getVariable ["Waldo_MG_MS_Finish", {}];
        [_disp, true] call _fin;
    };
}];

// Layout.
private _w = 0.42 * safezoneW;
private _headerH = 0.13 * safezoneH;
private _gridSpan = 0.42 * safezoneH;
private _h = _headerH + _gridSpan + 0.03 * safezoneH;
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

private _timer = _display ctrlCreate ["RscText", -1];
_timer ctrlSetPosition [_x, _y + 0.055 * safezoneH, _w, 0.04 * safezoneH];
_timer ctrlSetTextColor _cText;
_timer ctrlSetText format ["Reveal every safe cell.  Mines: %1", _mineCount];
_timer ctrlCommit 0;
_display setVariable ["Waldo_MG_MS_TimerCtrl", _timer];

// Grid.
private _gridTop = _y + _headerH;
private _cellGap = 0.004 * safezoneW;
private _cellW = (_w - (_size - 1) * _cellGap) / _size;
private _cellH = (_gridSpan - (_size - 1) * _cellGap) / _size;
private _colX = _x;
private _buttons = [];
for "_i" from 0 to (_cells - 1) do {
    private _row = floor (_i / _size);
    private _col = _i mod _size;
    private _cx = _colX + _col * (_cellW + _cellGap);
    private _cy = _gridTop + _row * (_cellH + _cellGap);
    private _btn = _display ctrlCreate ["RscButton", -1];
    _btn ctrlSetPosition [_cx, _cy, _cellW, _cellH];
    _btn ctrlSetText "";
    _btn ctrlSetBackgroundColor _cCell;
    _btn ctrlSetTextColor _cText;
    _btn setVariable ["Waldo_MG_MS_Index", _i];
    _btn ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = ctrlParent _ctrl;
        if (isNull _disp || {_disp getVariable ["Waldo_MG_MS_Done", false]}) exitWith {};
        private _idx = _ctrl getVariable ["Waldo_MG_MS_Index", -1];
        private _mines = _disp getVariable ["Waldo_MG_MS_Mines", []];
        private _rev = _disp getVariable ["Waldo_MG_MS_Revealed", []];
        private _flagged = _disp getVariable ["Waldo_MG_MS_Flagged", []];
        if (_rev select _idx) exitWith {};
        if (_flagged select _idx) exitWith {};
        if (_disp getVariable ["Waldo_MG_MS_FirstMove", true]) then {
            _disp setVariable ["Waldo_MG_MS_FirstMove", false];
            if (_mines select _idx) then {
                private _swap = -1;
                for "_candidate" from 0 to ((count _mines) - 1) do {
                    if (_swap < 0 && {!(_mines select _candidate)} && {_candidate != _idx}) then { _swap = _candidate; };
                };
                if (_swap >= 0) then {
                    _mines set [_idx, false];
                    _mines set [_swap, true];
                    _disp setVariable ["Waldo_MG_MS_Mines", _mines];
                    [_disp] call (_disp getVariable ["Waldo_MG_MS_RebuildAdj", {}]);
                };
            };
        };
        if (_mines select _idx) exitWith {
            _ctrl ctrlSetText "X";
            _ctrl ctrlSetBackgroundColor [0.80, 0.22, 0.20, 1];
            private _fin = _disp getVariable ["Waldo_MG_MS_Finish", {}];
            [_disp, false] call _fin;
        };
        private _reveal = _disp getVariable ["Waldo_MG_MS_Reveal", {}];
        [_disp, _idx] call _reveal;
    }];
    _btn ctrlAddEventHandler ["MouseButtonDown", {
        params ["_ctrl", "_button"];
        if (_button != 1) exitWith {};
        private _disp = ctrlParent _ctrl;
        private _idx = _ctrl getVariable ["Waldo_MG_MS_Index", -1];
        private _revealed = _disp getVariable ["Waldo_MG_MS_Revealed", []];
        if (_idx < 0 || {_revealed select _idx}) exitWith {};
        private _flagged = _disp getVariable ["Waldo_MG_MS_Flagged", []];
        _flagged set [_idx, !(_flagged select _idx)];
        _disp setVariable ["Waldo_MG_MS_Flagged", _flagged];
        _ctrl ctrlSetText if (_flagged select _idx) then {"FLAG"} else {""};
        _ctrl ctrlSetTextColor if (_flagged select _idx) then {[0.95, 0.72, 0.22, 1]} else {[0.88, 0.90, 0.94, 1]};
        private _timer = _disp getVariable ["Waldo_MG_MS_TimerCtrl", controlNull];
        if (!isNull _timer) then { _timer ctrlSetText format ["Reveal safe cells. Mines: %1  Flags: %2", {_x} count (_disp getVariable ["Waldo_MG_MS_Mines", []]), {_x} count _flagged]; };
    }];
    _btn ctrlCommit 0;
    _buttons pushBack _btn;
};
_display setVariable ["Waldo_MG_MS_Buttons", _buttons];

// Escape aborts (counts as a failure).
_display displayAddEventHandler ["KeyDown", {
    params ["_disp", "_key"];
    if (_key == 1) then {
        private _fin = _disp getVariable ["Waldo_MG_MS_Finish", {}];
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
        while { !isNull _disp && {!(_disp getVariable ["Waldo_MG_MS_Done", false])} } do {
            private _remain = _deadline - time;
            private _timerCtrl = _disp getVariable ["Waldo_MG_MS_TimerCtrl", controlNull];
            if (_remain <= 0) exitWith {
                private _fin = _disp getVariable ["Waldo_MG_MS_Finish", {}];
                [_disp, false, "timeoutText"] call _fin;
            };
            if (!isNull _timerCtrl) then {
                _timerCtrl ctrlSetText format ["TIME REMAINING: %1s", (_remain max 0) toFixed 1];
            };
            sleep 0.1;
        };
    };
};
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

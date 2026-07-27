/*
 * Portable ordnance diagnostic-tablet matrix procedure.
 * Config: [size(4..8), mineCount, timeLimit, title]
 */
disableSerialization;
params [["_config", []], ["_resolve", {}]];
_config params [["_size", 5], ["_mineCount", 5], ["_timeLimit", 0], ["_title", "TRIGGER ANALYSER"]];
_size = ((round _size) max 4) min 8;
private _cellCount = _size * _size;
_mineCount = ((round _mineCount) max 1) min (_cellCount - 9 max 1);

private _display = [
    _title,
    "Probe every safe circuit node. Mark suspected triggers before opening adjacent nodes.",
    _timeLimit,
    _resolve,
    0.50,
    "Left click: probe node; Right click: place/remove PROBE marker",
    "The first probe and its immediate neighbours are protected. Numerals report adjacent triggers."
] call Waldo_fnc_MiniGameChallengeUI;
if (isNull _display) exitWith {};

_display setVariable ["Waldo_MG_MS_Size", _size];
_display setVariable ["Waldo_MG_MS_MineCount", _mineCount];
_display setVariable ["Waldo_MG_MS_Mines", []];
_display setVariable ["Waldo_MG_MS_Revealed", []];
_display setVariable ["Waldo_MG_MS_Flags", []];
_display setVariable ["Waldo_MG_MS_Generated", false];
_display setVariable ["Waldo_MG_MS_Revealing", false];

private _tablet = [_display, "RscText", [1.5, 3, 37, 20.5], "portable ordnance diagnostic tablet"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_tablet ctrlSetBackgroundColor [0.10, 0.12, 0.115, 1];
private _screen = [_display, "RscText", [2.5, 4, 26.5, 18.3], "explosive circuit matrix screen"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_screen ctrlSetBackgroundColor [0.012, 0.027, 0.025, 1];
private _screenTitle = [_display, "RscText", [3.2, 4.35, 25.1, 1.3], "fault map screen label"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_screenTitle ctrlSetText "MX-12 // EXPLOSIVE CIRCUIT MATRIX";
_screenTitle ctrlSetTextColor [0.54, 0.92, 0.68, 1];
private _sidePanel = [_display, "RscText", [30, 4, 7.5, 18.3], "diagnostic counters panel"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_sidePanel ctrlSetBackgroundColor [0.045, 0.055, 0.052, 1];
private _counter = [_display, "RscStructuredText", [30.7, 5, 6.1, 7.2], "mine flag and scan counters"] call Waldo_fnc_MiniGameEquipmentCreateControl;
[_counter, "<t size='%1'><t color='#F2BE55'>TRIGGERS</t> --<br/><t color='#F2BE55'>MARKERS</t> 0<br/><t color='#F2BE55'>SAFE NODES</t> 0</t>", 0.90, 0.62] call Waldo_fnc_MiniGameEquipmentFitStructuredText;
_display setVariable ["Waldo_MG_MS_Counter", _counter];
private _legend = [_display, "RscStructuredText", [30.6, 12.5, 6.3, 8], "diagnostic matrix legend"] call Waldo_fnc_MiniGameEquipmentCreateControl;
[_legend, "<t size='%1'><t color='#DDD8C8'>MATRIX KEY</t><br/>[?] UNTESTED<br/>[P] PROBE MARKER<br/>[1-8] ADJACENT<br/>[ ] CLEAR<br/>[*] TRIGGER<br/><t color='#F2BE55'>RMB: MARK</t></t>", 0.75, 0.58] call Waldo_fnc_MiniGameEquipmentFitStructuredText;

private _boardX = 3.4;
private _boardY = 5.8;
private _boardW = 24.3;
private _boardH = 15.7;
private _cellW = _boardW / _size;
private _cellH = _boardH / _size;
private _buttons = [];
for "_row" from 0 to (_size - 1) do {
    for "_column" from 0 to (_size - 1) do {
        private _index = (_row * _size) + _column;
        private _button = [_display, "RscButton", [
            _boardX + (_column * _cellW),
            _boardY + (_row * _cellH),
            _cellW - 0.12,
            _cellH - 0.12
        ], format ["diagnostic node row %1 column %2", _row + 1, _column + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
        _button ctrlSetText "[?]";
        _button ctrlSetBackgroundColor [0.11, 0.17, 0.16, 1];
        _button ctrlSetTextColor [0.84, 0.88, 0.82, 1];
        _button ctrlSetTooltip format ["Circuit node %1-%2. LMB probe, RMB mark.", _row + 1, _column + 1];
        _button setVariable ["Waldo_MG_MS_Index", _index];
        _button ctrlAddEventHandler ["MouseButtonDown", {
            params ["_control", "_button"];
            private _display = ctrlParent _control;
            if (!(_display getVariable ["Waldo_IMG_Started", false]) || {_display getVariable ["Waldo_MG_UI_Done", false] || {_display getVariable ["Waldo_MG_MS_Revealing", false]}}) exitWith {true};
            private _index = _control getVariable ["Waldo_MG_MS_Index", -1];
            if (_button == 0) exitWith {[_display, _index] call (_display getVariable ["Waldo_MG_MS_Reveal", {}]); true};
            if (_button == 1) exitWith {[_display, _index] call (_display getVariable ["Waldo_MG_MS_ToggleFlag", {}]); true};
            false
        }];
        _buttons pushBack _button;
    };
};
_display setVariable ["Waldo_MG_MS_Buttons", _buttons];

_display setVariable ["Waldo_MG_MS_Generate", {
    params ["_display", "_firstIndex"];
    private _size = _display getVariable ["Waldo_MG_MS_Size", 5];
    private _mineCount = _display getVariable ["Waldo_MG_MS_MineCount", 5];
    private _firstRow = floor (_firstIndex / _size);
    private _firstColumn = _firstIndex mod _size;
    private _allowed = [];
    for "_index" from 0 to ((_size * _size) - 1) do {
        private _row = floor (_index / _size);
        private _column = _index mod _size;
        if (abs (_row - _firstRow) > 1 || {abs (_column - _firstColumn) > 1}) then {_allowed pushBack _index;};
    };
    if (count _allowed < _mineCount) then {
        _allowed = [];
        for "_index" from 0 to ((_size * _size) - 1) do {if (_index != _firstIndex) then {_allowed pushBack _index;};};
    };
    _allowed = _allowed call BIS_fnc_arrayShuffle;
    _display setVariable ["Waldo_MG_MS_Mines", _allowed select [0, _mineCount]];
    _display setVariable ["Waldo_MG_MS_Generated", true];
}];
_display setVariable ["Waldo_MG_MS_Adjacent", {
    params ["_display", "_index"];
    private _size = _display getVariable ["Waldo_MG_MS_Size", 5];
    private _row = floor (_index / _size);
    private _column = _index mod _size;
    private _neighbours = [];
    for "_rowOffset" from -1 to 1 do {
        for "_columnOffset" from -1 to 1 do {
            private _nextRow = _row + _rowOffset;
            private _nextColumn = _column + _columnOffset;
            if (!(_rowOffset == 0 && {_columnOffset == 0}) && {_nextRow >= 0 && {_nextRow < _size && {_nextColumn >= 0 && {_nextColumn < _size}}}}) then {
                _neighbours pushBack ((_nextRow * _size) + _nextColumn);
            };
        };
    };
    _neighbours
}];
_display setVariable ["Waldo_MG_MS_Refresh", {
    params ["_display", ["_loss", false]];
    private _buttons = _display getVariable ["Waldo_MG_MS_Buttons", []];
    private _mines = _display getVariable ["Waldo_MG_MS_Mines", []];
    private _revealed = _display getVariable ["Waldo_MG_MS_Revealed", []];
    private _flags = _display getVariable ["Waldo_MG_MS_Flags", []];
    {
        private _index = _forEachIndex;
        if (_index in _revealed) then {
            private _adjacent = {_x in _mines} count ([_display, _index] call (_display getVariable ["Waldo_MG_MS_Adjacent", {}]));
            _x ctrlSetText (if (_adjacent == 0) then {"[ ]"} else {format ["[%1]", _adjacent]});
            _x ctrlSetBackgroundColor [0.06, 0.11, 0.10, 1];
            _x ctrlSetTextColor [0.58, 0.90, 0.72, 1];
            _x ctrlEnable false;
        } else {
            if (_loss && {_index in _mines}) then {
                _x ctrlSetText "[*] TRIGGER";
                _x ctrlSetBackgroundColor [0.42, 0.06, 0.12, 1];
                _x ctrlSetTextColor [1, 0.74, 0.80, 1];
                _x ctrlEnable false;
            } else {
                if (_index in _flags) then {
                    _x ctrlSetText "[P]";
                    _x ctrlSetBackgroundColor [0.34, 0.28, 0.08, 1];
                    _x ctrlSetTextColor [1, 0.88, 0.42, 1];
                } else {
                    _x ctrlSetText "[?]";
                    _x ctrlSetBackgroundColor [0.11, 0.17, 0.16, 1];
                    _x ctrlSetTextColor [0.84, 0.88, 0.82, 1];
                };
            };
        };
    } forEach _buttons;
    private _counter = _display getVariable ["Waldo_MG_MS_Counter", controlNull];
    if (!isNull _counter) then {
        private _counterTemplate = "<t size='%1'><t color='#F2BE55'>TRIGGERS</t> "
            + str (count _mines)
            + "<br/><t color='#F2BE55'>MARKERS</t> "
            + str (count _flags)
            + "<br/><t color='#F2BE55'>SAFE NODES</t> "
            + str (count _revealed)
            + "/"
            + str ((count _buttons) - count _mines)
            + "</t>";
        [_counter, _counterTemplate, 0.90, 0.62] call Waldo_fnc_MiniGameEquipmentFitStructuredText;
    };
}];
_display setVariable ["Waldo_MG_MS_ToggleFlag", {
    params ["_display", "_index"];
    if (_index in (_display getVariable ["Waldo_MG_MS_Revealed", []])) exitWith {};
    private _flags = _display getVariable ["Waldo_MG_MS_Flags", []];
    if (_index in _flags) then {_flags deleteAt (_flags find _index);} else {
        if (count _flags < (_display getVariable ["Waldo_MG_MS_MineCount", 1])) then {_flags pushBack _index;};
    };
    _display setVariable ["Waldo_MG_MS_Flags", _flags];
    [_display] call (_display getVariable ["Waldo_MG_MS_Refresh", {}]);
}];
_display setVariable ["Waldo_MG_MS_Reveal", {
    params ["_display", "_index"];
    if (_index in (_display getVariable ["Waldo_MG_MS_Flags", []]) || {_index in (_display getVariable ["Waldo_MG_MS_Revealed", []])}) exitWith {};
    if !(_display getVariable ["Waldo_MG_MS_Generated", false]) then {[_display, _index] call (_display getVariable ["Waldo_MG_MS_Generate", {}]);};
    private _mines = _display getVariable ["Waldo_MG_MS_Mines", []];
    if (_index in _mines) exitWith {
        [_display, true] call (_display getVariable ["Waldo_MG_MS_Refresh", {}]);
        [_display, false, "[X] LIVE TRIGGER NODE PROBED"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
    };
    _display setVariable ["Waldo_MG_MS_Revealing", true];
    private _worker = [_display, _index] spawn {
        params ["_display", "_start"];
        private _queue = [_start];
        private _revealed = _display getVariable ["Waldo_MG_MS_Revealed", []];
        private _mines = _display getVariable ["Waldo_MG_MS_Mines", []];
        private _flags = _display getVariable ["Waldo_MG_MS_Flags", []];
        while {count _queue > 0 && {!isNull _display}} do {
            private _current = _queue deleteAt 0;
            if (!(_current in _revealed) && {!(_current in _flags) && {!(_current in _mines)}}) then {
                _revealed pushBack _current;
                _display setVariable ["Waldo_MG_MS_Revealed", _revealed];
                [_display] call (_display getVariable ["Waldo_MG_MS_Refresh", {}]);
                private _adjacent = [_display, _current] call (_display getVariable ["Waldo_MG_MS_Adjacent", {}]);
                if ({_x in _mines} count _adjacent == 0) then {
                    {_queue pushBackUnique _x;} forEach _adjacent;
                };
                if !(_display getVariable ["Waldo_IMG_ReducedMotion", false]) then {uiSleep 0.025;};
            };
        };
        if (!isNull _display) then {
            _display setVariable ["Waldo_MG_MS_Revealing", false];
            private _safeTotal = count (_display getVariable ["Waldo_MG_MS_Buttons", []]) - count _mines;
            if (count (_display getVariable ["Waldo_MG_MS_Revealed", []]) >= _safeTotal) then {
                [_display, true, "[OK] EXPLOSIVE CIRCUIT MATRIX CLEARED"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
            } else {
                private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
                if (!isNull _status) then {_status ctrlSetText format ["[SCAN] %1 SAFE NODES REMAIN", _safeTotal - count (_display getVariable ["Waldo_MG_MS_Revealed", []])];};
            };
        };
    };
    private _workers = _display getVariable ["Waldo_MG_UI_Workers", []];
    _workers pushBack _worker;
    _display setVariable ["Waldo_MG_UI_Workers", _workers];
}];
[_display] call (_display getVariable ["Waldo_MG_MS_Refresh", {}]);
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

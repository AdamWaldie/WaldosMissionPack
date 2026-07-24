/*
 * Breaker-cabinet continuity routing procedure.
 * Config: [pairs(3..6), maxMistakes, timeLimit, title]
 */
disableSerialization;
params [["_config", []], ["_resolve", {}]];
_config params [["_pairs", 4], ["_maxMistakes", 3], ["_timeLimit", 0], ["_title", "BREAKER CABINET"]];
_pairs = ((round _pairs) max 3) min 6;
_maxMistakes = (round _maxMistakes) max 0;

private _display = [
    _title,
    "Route each isolated breaker output to the matching distribution-bus terminal.",
    _timeLimit,
    _resolve,
    0.49,
    "Mouse: select SOURCE terminal, then matching BUS terminal",
    "Match the terminal code and symbol. Cable colour is supplementary."
] call Waldo_fnc_MiniGameChallengeUI;
if (isNull _display) exitWith {};

private _identities = [
    ["A1", "TRIANGLE", [0.30, 0.62, 0.88, 1]],
    ["B2", "SQUARE", [0.88, 0.42, 0.30, 1]],
    ["C3", "DOTS", [0.36, 0.72, 0.42, 1]],
    ["D4", "DIAMOND", [0.92, 0.72, 0.26, 1]],
    ["E5", "CROSS", [0.64, 0.44, 0.78, 1]],
    ["F6", "BARS", [0.30, 0.74, 0.74, 1]]
];
private _rightOrder = [];
for "_index" from 0 to (_pairs - 1) do {_rightOrder pushBack _index;};
_rightOrder = _rightOrder call BIS_fnc_arrayShuffle;
if (_rightOrder isEqualTo ([0, 1, 2, 3, 4, 5] select [0, _pairs])) then {reverse _rightOrder;};

_display setVariable ["Waldo_MG_CR_ActiveLeft", -1];
_display setVariable ["Waldo_MG_CR_LeftDone", []];
_display setVariable ["Waldo_MG_CR_RightDone", []];
_display setVariable ["Waldo_MG_CR_Connected", 0];
_display setVariable ["Waldo_MG_CR_Total", _pairs];
_display setVariable ["Waldo_MG_CR_Mistakes", 0];
_display setVariable ["Waldo_MG_CR_MaxMistakes", _maxMistakes];
_display setVariable ["Waldo_MG_CR_RightOrder", _rightOrder];
_display setVariable ["Waldo_MG_CR_Identities", _identities];

private _cabinet = [_display, "RscText", [1.5, 3, 37, 20], "breaker cabinet casing"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_cabinet ctrlSetBackgroundColor [0.11, 0.13, 0.12, 1];
private _sourceBay = [_display, "RscText", [2.5, 5, 11, 16.8], "isolated breaker bank"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_sourceBay ctrlSetBackgroundColor [0.045, 0.055, 0.052, 1];
private _busBay = [_display, "RscText", [26.5, 5, 11, 16.8], "distribution bus bank"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_busBay ctrlSetBackgroundColor [0.045, 0.055, 0.052, 1];
private _sourceTitle = [_display, "RscText", [3, 3.6, 10, 1.2], "source bank label"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_sourceTitle ctrlSetText "ISOLATED BREAKERS";
_sourceTitle ctrlSetTextColor [0.82, 0.86, 0.78, 1];
private _busTitle = [_display, "RscText", [27, 3.6, 10, 1.2], "bus bank label"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_busTitle ctrlSetText "DISTRIBUTION BUS";
_busTitle ctrlSetTextColor [0.82, 0.86, 0.78, 1];
private _busBar = [_display, "RscText", [19.65, 5.2, 0.7, 16.2], "central bus bar"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_busBar ctrlSetBackgroundColor [0.46, 0.39, 0.24, 1];
private _meter = [_display, "RscText", [15.1, 3.5, 9.8, 1.5], "continuity meter"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_meter ctrlSetText format ["CONTINUITY  0 / %1", _pairs];
_meter ctrlSetBackgroundColor [0.01, 0.025, 0.018, 1];
_meter ctrlSetTextColor [0.62, 0.92, 0.68, 1];
_display setVariable ["Waldo_MG_CR_Meter", _meter];

private _rowHeight = 15 / _pairs;
private _leftButtons = [];
private _rightButtons = [];
private _leftDone = [];
private _rightDone = [];
for "_row" from 0 to (_pairs - 1) do {
    private _identity = _identities select _row;
    private _y = 5.8 + (_row * _rowHeight);
    private _breaker = [_display, "RscButton", [3.2, _y, 9.5, _rowHeight - 0.45], format ["source terminal %1 %2", _identity select 0, _identity select 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _breaker ctrlSetText format ["SRC %1  <%2>", _identity select 0, _identity select 1];
    _breaker ctrlSetBackgroundColor [0.13, 0.16, 0.15, 1];
    _breaker ctrlSetTextColor (_identity select 2);
    _breaker ctrlSetTooltip format ["Source %1, %2 symbol", _identity select 0, _identity select 1];
    _breaker setVariable ["Waldo_MG_CR_Side", "LEFT"];
    _breaker setVariable ["Waldo_MG_CR_Index", _row];
    _leftButtons pushBack _breaker;
    _leftDone pushBack false;

    private _rightIdentityIndex = _rightOrder select _row;
    private _rightIdentity = _identities select _rightIdentityIndex;
    private _terminal = [_display, "RscButton", [27.3, _y, 9.5, _rowHeight - 0.45], format ["bus terminal %1 %2", _rightIdentity select 0, _rightIdentity select 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _terminal ctrlSetText format ["BUS %1  <%2>", _rightIdentity select 0, _rightIdentity select 1];
    _terminal ctrlSetBackgroundColor [0.13, 0.16, 0.15, 1];
    _terminal ctrlSetTextColor (_rightIdentity select 2);
    _terminal ctrlSetTooltip format ["Bus %1, %2 symbol", _rightIdentity select 0, _rightIdentity select 1];
    _terminal setVariable ["Waldo_MG_CR_Side", "RIGHT"];
    _terminal setVariable ["Waldo_MG_CR_Index", _row];
    _terminal setVariable ["Waldo_MG_CR_IdentityIndex", _rightIdentityIndex];
    _rightButtons pushBack _terminal;
    _rightDone pushBack false;
};
_display setVariable ["Waldo_MG_CR_LeftBtns", _leftButtons];
_display setVariable ["Waldo_MG_CR_RightBtns", _rightButtons];
_display setVariable ["Waldo_MG_CR_LeftDone", _leftDone];
_display setVariable ["Waldo_MG_CR_RightDone", _rightDone];

_display setVariable ["Waldo_MG_CR_Select", {
    params ["_control"];
    private _display = ctrlParent _control;
    if (!(_display getVariable ["Waldo_IMG_Started", false]) || {_display getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
    private _side = _control getVariable ["Waldo_MG_CR_Side", ""];
    private _index = _control getVariable ["Waldo_MG_CR_Index", -1];
    private _leftDone = _display getVariable ["Waldo_MG_CR_LeftDone", []];
    private _rightDone = _display getVariable ["Waldo_MG_CR_RightDone", []];
    if (_side == "LEFT") exitWith {
        if (_leftDone param [_index, false]) exitWith {};
        _display setVariable ["Waldo_MG_CR_ActiveLeft", _index];
        {
            if !(_leftDone param [_forEachIndex, false]) then {
                _x ctrlSetBackgroundColor (if (_forEachIndex == _index) then {[0.30, 0.27, 0.12, 1]} else {[0.13, 0.16, 0.15, 1]});
            };
        } forEach (_display getVariable ["Waldo_MG_CR_LeftBtns", []]);
        private _identity = (_display getVariable ["Waldo_MG_CR_Identities", []]) select _index;
        private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
        if (!isNull _status) then {_status ctrlSetText format ["[SELECTED] SRC %1 <%2> // CHOOSE MATCHING BUS", _identity select 0, _identity select 1];};
    };
    if (_rightDone param [_index, false]) exitWith {};
    private _active = _display getVariable ["Waldo_MG_CR_ActiveLeft", -1];
    if (_active < 0) exitWith {
        private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
        if (!isNull _status) then {_status ctrlSetText "[!] SELECT A SOURCE BREAKER FIRST";};
    };
    private _rightIdentity = _control getVariable ["Waldo_MG_CR_IdentityIndex", -1];
    if (_rightIdentity == _active) then {
        _leftDone set [_active, true];
        _rightDone set [_index, true];
        _display setVariable ["Waldo_MG_CR_LeftDone", _leftDone];
        _display setVariable ["Waldo_MG_CR_RightDone", _rightDone];
        private _leftButtons = _display getVariable ["Waldo_MG_CR_LeftBtns", []];
        private _rightButtons = _display getVariable ["Waldo_MG_CR_RightBtns", []];
        private _left = _leftButtons select _active;
        private _right = _rightButtons select _index;
        _left ctrlSetText format ["SRC %1 [LINKED]", ((_display getVariable ["Waldo_MG_CR_Identities", []]) select _active) select 0];
        _right ctrlSetText format ["BUS %1 [LINKED]", ((_display getVariable ["Waldo_MG_CR_Identities", []]) select _active) select 0];
        _left ctrlSetBackgroundColor [0.10, 0.32, 0.19, 1];
        _right ctrlSetBackgroundColor [0.10, 0.32, 0.19, 1];
        _left ctrlEnable false;
        _right ctrlEnable false;
        private _leftY = 5.8 + (_active * (15 / (_display getVariable ["Waldo_MG_CR_Total", 1]))) + ((15 / (_display getVariable ["Waldo_MG_CR_Total", 1])) / 2);
        private _rightY = 5.8 + (_index * (15 / (_display getVariable ["Waldo_MG_CR_Total", 1]))) + ((15 / (_display getVariable ["Waldo_MG_CR_Total", 1])) / 2);
        private _colour = (((_display getVariable ["Waldo_MG_CR_Identities", []]) select _active) select 2);
        [_display, [[12.7, _leftY], [17.5, _leftY], [17.5, _rightY], [27.3, _rightY]], _colour, 0.24, format ["linked cable %1 with labelled elbow route", _active + 1]] call Waldo_fnc_MiniGameEquipmentPolyline;
        private _connected = (_display getVariable ["Waldo_MG_CR_Connected", 0]) + 1;
        _display setVariable ["Waldo_MG_CR_Connected", _connected];
        _display setVariable ["Waldo_MG_CR_ActiveLeft", -1];
        private _meter = _display getVariable ["Waldo_MG_CR_Meter", controlNull];
        if (!isNull _meter) then {_meter ctrlSetText format ["CONTINUITY  %1 / %2  [OK]", _connected, _display getVariable ["Waldo_MG_CR_Total", 1]];};
        if (_connected >= (_display getVariable ["Waldo_MG_CR_Total", 1])) then {
            [_display, true, "[OK] DISTRIBUTION BUS ENERGIZED"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
        };
    } else {
        private _mistakes = (_display getVariable ["Waldo_MG_CR_Mistakes", 0]) + 1;
        _display setVariable ["Waldo_MG_CR_Mistakes", _mistakes];
        private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
        if (!isNull _status) then {_status ctrlSetText format ["[X] CONTINUITY MISMATCH // MISTAKES %1/%2", _mistakes, _display getVariable ["Waldo_MG_CR_MaxMistakes", 0]];};
        _control ctrlSetBackgroundColor [0.42, 0.08, 0.14, 1];
        if (_mistakes >= ((_display getVariable ["Waldo_MG_CR_MaxMistakes", 0]) max 1)) then {
            [_display, false, "[X] BREAKER ROUTING FAULT"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
        };
    };
}];
{{_x ctrlAddEventHandler ["ButtonClick", {[_this select 0] call ((ctrlParent (_this select 0)) getVariable ["Waldo_MG_CR_Select", {}]);}];} forEach _x;} forEach [_leftButtons, _rightButtons];
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

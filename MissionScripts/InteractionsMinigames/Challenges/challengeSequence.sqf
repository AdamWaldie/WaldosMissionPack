/*
 * Author: Waldo
 * Control-sequence interaction challenge. Watch illuminated pads and reproduce progressively
 * longer sequences with the mouse or number keys.
 *
 * Arguments:
 * _config  - Array - [padCount(3..6), rounds(1..8), playbackSpeed, timeLimit, title]
 * _resolve - Code  - called once with boolean success and typed outcome metadata
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [[4, 4, 0.6, 0, "CONTROL SEQUENCE"], {}] call Waldo_fnc_MiniGameSequence;
 */

disableSerialization;
params [["_config", []], ["_resolve", {}]];
_config params [["_padCount", 4], ["_rounds", 4], ["_speed", 0.6], ["_timeLimit", 0], ["_title", "CONTROL CONSOLE"]];
_padCount = ((round _padCount) max 3) min 6;
_rounds = ((round _rounds) max 1) min 8;
_speed = (_speed max 0.25) min 1.5;

private _display = [_title, "Watch the illuminated control sequence, then repeat it exactly.", _timeLimit, _resolve, 0.45, "Mouse or number keys 1-6: activate pads", "Wait for YOUR TURN before entering the sequence. Each successful round adds one more pad."] call Waldo_fnc_MiniGameChallengeUI;
if (isNull _display) exitWith {};
private _content = _display getVariable ["Waldo_MG_UI_Content", []];
_content params ["_x", "_y", "_w", "_h"];
_display setVariable ["Waldo_MG_SQ_Sequence", [floor (random _padCount)]];
_display setVariable ["Waldo_MG_SQ_Input", 0];
_display setVariable ["Waldo_MG_SQ_Round", 1];
_display setVariable ["Waldo_MG_SQ_Rounds", _rounds];
_display setVariable ["Waldo_MG_SQ_Speed", _speed];
_display setVariable ["Waldo_MG_SQ_PadCount", _padCount];
_display setVariable ["Waldo_MG_SQ_AcceptInput", false];

private _colours = [
    [[0.20, 0.42, 0.85, 1], "BLUE"], [[0.80, 0.24, 0.24, 1], "RED"],
    [[0.22, 0.62, 0.30, 1], "GREEN"], [[0.86, 0.72, 0.20, 1], "AMBER"],
    [[0.62, 0.36, 0.78, 1], "PURPLE"], [[0.20, 0.68, 0.72, 1], "CYAN"]
];
private _shapes = ["TRIANGLE", "SQUARE", "DOT", "DIAMOND", "CROSS", "HEX"];
private _buttons = [];
private _cols = if (_padCount <= 4) then {2} else {3};
private _rows = ceil (_padCount / _cols);
private _bw = (_w - 0.08 * safezoneW) / _cols;
private _bh = (_h - 0.12 * safezoneH) / _rows;
for "_i" from 0 to (_padCount - 1) do {
    private _col = _i mod _cols;
    private _row = floor (_i / _cols);
    private _button = _display ctrlCreate ["RscButton", -1];
    _button ctrlSetPosition [_x + 0.03 * safezoneW + _col * (_bw + 0.02 * safezoneW), _y + 0.07 * safezoneH + _row * (_bh + 0.015 * safezoneH), _bw, _bh];
    _button ctrlSetText format ["%1  [%2]  %3", _i + 1, _shapes select _i, (_colours select _i) select 1];
    _button ctrlSetBackgroundColor (((_colours select _i) select 0) apply {_x * 0.45});
    _button ctrlSetTextColor [0.92, 0.94, 0.98, 1];
    _button setVariable ["Waldo_MG_SQ_Index", _i];
    _button ctrlCommit 0;
    _buttons pushBack _button;
};
_display setVariable ["Waldo_MG_SQ_Buttons", _buttons];
_display setVariable ["Waldo_MG_SQ_Colours", _colours];

_display setVariable ["Waldo_MG_SQ_Press", {
    params ["_disp", "_index"];
    if !(_disp getVariable ["Waldo_IMG_Started", false]) exitWith {};
    if !(_disp getVariable ["Waldo_MG_SQ_AcceptInput", false]) exitWith {};
    private _sequence = _disp getVariable ["Waldo_MG_SQ_Sequence", []];
    private _input = _disp getVariable ["Waldo_MG_SQ_Input", 0];
    if (_index != (_sequence select _input)) exitWith {
        [_disp, false, "INCORRECT SEQUENCE"] call (_disp getVariable ["Waldo_MG_UI_Finish", {}]);
    };
    _input = _input + 1;
    _disp setVariable ["Waldo_MG_SQ_Input", _input];
    private _status = _disp getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then { _status ctrlSetText format ["INPUT %1 / %2", _input, count _sequence]; };
    if (_input >= count _sequence) then {
        _disp setVariable ["Waldo_MG_SQ_AcceptInput", false];
        private _round = _disp getVariable ["Waldo_MG_SQ_Round", 1];
        if (_round >= (_disp getVariable ["Waldo_MG_SQ_Rounds", 1])) exitWith {
            [_disp, true, "SEQUENCE ACCEPTED"] call (_disp getVariable ["Waldo_MG_UI_Finish", {}]);
        };
        _round = _round + 1;
        _disp setVariable ["Waldo_MG_SQ_Round", _round];
        _sequence pushBack (floor (random (_disp getVariable ["Waldo_MG_SQ_PadCount", 4])));
        _disp setVariable ["Waldo_MG_SQ_Sequence", _sequence];
        _disp setVariable ["Waldo_MG_SQ_Input", 0];
        [_disp] spawn (_disp getVariable ["Waldo_MG_SQ_Play", {}]);
    };
}];
{
    _x ctrlAddEventHandler ["ButtonClick", { params ["_ctrl"]; private _disp = ctrlParent _ctrl; [_disp, _ctrl getVariable ["Waldo_MG_SQ_Index", -1]] call (_disp getVariable ["Waldo_MG_SQ_Press", {}]); }];
} forEach _buttons;

_display setVariable ["Waldo_MG_SQ_Play", {
    params ["_disp"];
    waitUntil {isNull _disp || {_disp getVariable ["Waldo_IMG_Started", false]}};
    if (isNull _disp) exitWith {};
    sleep 0.55;
    if (isNull _disp || {_disp getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
    private _buttons = _disp getVariable ["Waldo_MG_SQ_Buttons", []];
    private _colours = _disp getVariable ["Waldo_MG_SQ_Colours", []];
    private _speed = _disp getVariable ["Waldo_MG_SQ_Speed", 0.6];
    private _status = _disp getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then { _status ctrlSetText format ["ROUND %1 / %2 - WATCH", _disp getVariable ["Waldo_MG_SQ_Round", 1], _disp getVariable ["Waldo_MG_SQ_Rounds", 1]]; };
    {
        if (isNull _disp || {_disp getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
        private _button = _buttons select _x;
        _button ctrlSetBackgroundColor ((_colours select _x) select 0);
        sleep (_speed * 0.55);
        _button ctrlSetBackgroundColor (((_colours select _x) select 0) apply {_x * 0.45});
        sleep (_speed * 0.45);
    } forEach (_disp getVariable ["Waldo_MG_SQ_Sequence", []]);
    if (!isNull _disp && {!(_disp getVariable ["Waldo_MG_UI_Done", false])}) then {
        _disp setVariable ["Waldo_MG_SQ_AcceptInput", true];
        if (!isNull _status) then { _status ctrlSetText "[INPUT ENABLED]  YOUR TURN"; };
    };
}];
_display displayAddEventHandler ["KeyDown", {
    params ["_disp", "_key"];
    private _numberKeys = [2, 3, 4, 5, 6, 7];
    private _index = _numberKeys find _key;
    if (_index >= 0 && {_index < (_disp getVariable ["Waldo_MG_SQ_PadCount", 4])}) exitWith {
        [_disp, _index] call (_disp getVariable ["Waldo_MG_SQ_Press", {}]);
        true
    };
    false
}];
[_display] spawn (_display getVariable ["Waldo_MG_SQ_Play", {}]);
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

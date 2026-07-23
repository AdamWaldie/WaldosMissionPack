/*
 * Author: Waldo
 * Pressure-balancing interaction challenge. Coupled valves move their own and neighbouring
 * gauges; every gauge must remain inside its marked safe band for the settle period.
 *
 * Arguments:
 * _config  - Array - [valveCount(2..4), difficulty(1..3), settleTime, timeLimit, title]
 * _resolve - Code  - called exactly once with [_success]
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [[3, 1, 2, 45, "PRESSURE CONTROL"], {}] call Waldo_fnc_MiniGamePressure;
 */

disableSerialization;
params [["_config", []], ["_resolve", {}]];
_config params [["_valveCount", 3], ["_difficulty", 1], ["_settleTime", 2], ["_timeLimit", 45], ["_title", "HYDRAULIC MANIFOLD"]];
_valveCount = ((round _valveCount) max 2) min 4;
_difficulty = ((round _difficulty) max 1) min 3;
_settleTime = _settleTime max 0.5;
private _band = [0.11, 0.08, 0.055] select (_difficulty - 1);

private _display = [_title, "Balance every gauge inside its marked safe band and hold the system stable.", _timeLimit, _resolve, 0.48, "Mouse: use -/+ valves; neighbouring gauges are coupled", "Adjust one valve at a time and watch every gauge: opening a valve slightly reduces its neighbour."] call Waldo_fnc_MiniGameChallengeUI;
if (isNull _display) exitWith {};
private _content = _display getVariable ["Waldo_MG_UI_Content", []];
_content params ["_x", "_y", "_w"];

private _values = [];
private _targets = [];
for "_i" from 0 to (_valveCount - 1) do {
    _values pushBack (0.1 + random 0.8);
    _targets pushBack (0.28 + random 0.44);
};
private _allInitiallySafe = true;
for "_i" from 0 to ((count _targets) - 1) do {
    if (abs ((_values select _i) - (_targets select _i)) > _band) exitWith {_allInitiallySafe = false;};
};
if (_allInitiallySafe) then {
    _values set [0, (((_targets select 0) + _band + 0.22) max 0) min 1];
};
_display setVariable ["Waldo_MG_PR_Values", _values];
_display setVariable ["Waldo_MG_PR_Targets", _targets];
_display setVariable ["Waldo_MG_PR_Band", _band];
_display setVariable ["Waldo_MG_PR_Settle", _settleTime];
_display setVariable ["Waldo_MG_PR_StableStart", -1];

private _pipe = _display ctrlCreate ["RscText", -1];
_pipe ctrlSetPosition [_x + 0.05 * safezoneW, _y + 0.325 * safezoneH, _w - 0.10 * safezoneW, 0.014 * safezoneH];
_pipe ctrlSetBackgroundColor [0.36, 0.38, 0.37, 1];
_pipe ctrlSetText "<== COUPLED MANIFOLD ==>";
_pipe ctrlSetTextColor [0.08, 0.09, 0.08, 1];
_pipe ctrlSetFontHeight (0.012 * safezoneH);
_pipe ctrlCommit 0;

private _bars = [];
private _needles = [];
private _labels = [];
private _columnW = (_w - 0.04 * safezoneW) / _valveCount;
for "_i" from 0 to (_valveCount - 1) do {
    private _cx = _x + 0.02 * safezoneW + _i * _columnW;
    private _label = _display ctrlCreate ["RscText", -1];
    _label ctrlSetPosition [_cx, _y + 0.06 * safezoneH, _columnW - 0.01 * safezoneW, 0.04 * safezoneH];
    _label ctrlSetText format ["GAUGE %1", _i + 1];
    _label ctrlSetTextColor [0.72, 0.94, 1, 1];
    _label ctrlCommit 0;
    _labels pushBack _label;
    private _bar = _display ctrlCreate ["RscText", -1];
    _bar ctrlSetPosition [_cx + (_columnW * 0.38), _y + 0.11 * safezoneH, _columnW * 0.24, 0.22 * safezoneH];
    _bar ctrlSetBackgroundColor [0.02, 0.03, 0.04, 1];
    _bar ctrlCommit 0;
    _bars pushBack _bar;
    private _safe = _display ctrlCreate ["RscText", -1];
    _safe ctrlSetBackgroundColor [0.22, 0.62, 0.30, 0.55];
    _safe ctrlCommit 0;
    _safe setVariable ["Waldo_MG_PR_Index", _i];
    _display setVariable [format ["Waldo_MG_PR_Safe_%1", _i], _safe];
    private _needle = _display ctrlCreate ["RscText", -1];
    _needle ctrlSetBackgroundColor [0.72, 0.94, 1, 1];
    _needle ctrlCommit 0;
    _needles pushBack _needle;
    private _minus = _display ctrlCreate ["RscButton", -1];
    _minus ctrlSetPosition [_cx, _y + 0.355 * safezoneH, (_columnW - 0.015 * safezoneW) / 2, 0.055 * safezoneH];
    _minus ctrlSetText "CLOSE -";
    _minus setVariable ["Waldo_MG_PR_Index", _i];
    _minus setVariable ["Waldo_MG_PR_Delta", -0.04];
    _minus ctrlCommit 0;
    private _plus = _display ctrlCreate ["RscButton", -1];
    _plus ctrlSetPosition [_cx + (_columnW + 0.005 * safezoneW) / 2, _y + 0.355 * safezoneH, (_columnW - 0.015 * safezoneW) / 2, 0.055 * safezoneH];
    _plus ctrlSetText "OPEN +";
    _plus setVariable ["Waldo_MG_PR_Index", _i];
    _plus setVariable ["Waldo_MG_PR_Delta", 0.04];
    _plus ctrlCommit 0;
    {
        _x ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = ctrlParent _ctrl;
            private _index = _ctrl getVariable ["Waldo_MG_PR_Index", 0];
            private _delta = _ctrl getVariable ["Waldo_MG_PR_Delta", 0];
            private _values = _disp getVariable ["Waldo_MG_PR_Values", []];
            for "_j" from 0 to ((count _values) - 1) do {
                private _coupling = if (_j == _index) then {1} else {if (abs (_j - _index) == 1) then {-0.22} else {0}};
                _values set [_j, (((_values select _j) + _delta * _coupling) max 0) min 1];
            };
            _disp setVariable ["Waldo_MG_PR_Values", _values];
            _disp setVariable ["Waldo_MG_PR_StableStart", -1];
            [_disp] call (_disp getVariable ["Waldo_MG_PR_Refresh", {}]);
        }];
    } forEach [_minus, _plus];
};
_display setVariable ["Waldo_MG_PR_Bars", _bars];
_display setVariable ["Waldo_MG_PR_Needles", _needles];
_display setVariable ["Waldo_MG_PR_Labels", _labels];

_display setVariable ["Waldo_MG_PR_Refresh", {
    params ["_disp"];
    private _content = _disp getVariable ["Waldo_MG_UI_Content", []];
    _content params ["_x", "_y", "_w"];
    private _values = _disp getVariable ["Waldo_MG_PR_Values", []];
    private _targets = _disp getVariable ["Waldo_MG_PR_Targets", []];
    private _band = _disp getVariable ["Waldo_MG_PR_Band", 0.1];
    private _needles = _disp getVariable ["Waldo_MG_PR_Needles", []];
    private _labels = _disp getVariable ["Waldo_MG_PR_Labels", []];
    private _columnW = (_w - 0.04 * safezoneW) / count _values;
    private _allSafe = true;
    for "_i" from 0 to ((count _values) - 1) do {
        private _cx = _x + 0.02 * safezoneW + _i * _columnW;
        private _target = _targets select _i;
        private _safeCtrl = _disp getVariable [format ["Waldo_MG_PR_Safe_%1", _i], controlNull];
        if (!isNull _safeCtrl) then { _safeCtrl ctrlSetPosition [_cx + _columnW * 0.38, _y + 0.11 * safezoneH + (1 - ((_target + _band) min 1)) * 0.22 * safezoneH, _columnW * 0.24, 2 * _band * 0.22 * safezoneH]; _safeCtrl ctrlCommit 0; };
        private _needle = _needles select _i;
        _needle ctrlSetPosition [_cx + _columnW * 0.34, _y + 0.11 * safezoneH + (1 - (_values select _i)) * 0.22 * safezoneH, _columnW * 0.32, 0.005 * safezoneH];
        _needle ctrlCommit 0;
        private _safe = abs ((_values select _i) - _target) <= _band;
        private _direction = if (_safe) then {"[SAFE]"} else {if ((_values select _i) < (_target - _band)) then {"[LOW ^]"} else {"[HIGH v]"}};
        (_labels select _i) ctrlSetText format ["GAUGE %1  %2", _i + 1, _direction];
        (_labels select _i) ctrlSetTextColor if (_safe) then {[0.55, 1, 0.65, 1]} else {[0.94, 0.78, 0.30, 1]};
        if (!_safe) then { _allSafe = false; };
    };
    if (_allSafe && {(_disp getVariable ["Waldo_MG_PR_StableStart", -1]) < 0}) then { _disp setVariable ["Waldo_MG_PR_StableStart", time]; };
    if (!_allSafe) then { _disp setVariable ["Waldo_MG_PR_StableStart", -1]; };
    private _status = _disp getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then { _status ctrlSetText if (_allSafe) then {"[SAFE] ALL LINES - HOLD STEADY"} else {"[ADJUST] FOLLOW LOW/HIGH GAUGE LABELS"}; };
}];
[_display] call (_display getVariable ["Waldo_MG_PR_Refresh", {}]);
[_display] spawn {
    params ["_disp"];
    waitUntil {isNull _disp || {_disp getVariable ["Waldo_IMG_Started", false]}};
    if (isNull _disp) exitWith {};
    while {!isNull _disp && {!(_disp getVariable ["Waldo_MG_UI_Done", false])}} do {
        private _stable = _disp getVariable ["Waldo_MG_PR_StableStart", -1];
        if (_stable >= 0 && {(time - _stable) >= (_disp getVariable ["Waldo_MG_PR_Settle", 2])}) exitWith {
            [_disp, true, "SYSTEM STABLE"] call (_disp getVariable ["Waldo_MG_UI_Finish", {}]);
        };
        sleep 0.05;
    };
};
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

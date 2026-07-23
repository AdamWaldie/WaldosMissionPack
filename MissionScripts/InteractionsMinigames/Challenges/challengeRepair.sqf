/*
 * Author: Waldo
 * Bolt-repair interaction challenge. Players select loose bolts and drag the illustrated wrench
 * clockwise until each reaches its torque target. Reversing the tool records a mistake.
 *
 * Arguments:
 * _config  - Array - [boltCount(3..6), turnsRequired(1..4), maxMistakes, timeLimit, title]
 * _resolve - Code  - called once with boolean success and typed outcome metadata
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [[4, 2, 3, 30, "REPAIR"], {systemChat str (_this select 0);}] call Waldo_fnc_MiniGameRepair;
 */

disableSerialization;
params [["_config", []], ["_resolve", {}]];
_config params [["_boltCount", 4], ["_turns", 2], ["_maxMistakes", 3], ["_timeLimit", 30], ["_title", "MAINTENANCE HATCH"]];
_boltCount = ((round _boltCount) max 3) min 6;
_turns = ((round _turns) max 1) min 4;
_maxMistakes = (round _maxMistakes) max 0;

private _display = [_title, "Select a loose bolt, then drag the wrench clockwise until its torque ring is full.", _timeLimit, _resolve, 0.49, "Mouse: select bolt / drag wrench clockwise", "Release the wrench when a bolt reaches 100%. Reversing or continuing to turn a completed bolt records a mistake."] call Waldo_fnc_MiniGameChallengeUI;
if (isNull _display) exitWith {};
private _content = _display getVariable ["Waldo_MG_UI_Content", []];
_content params ["_x", "_y", "_w", "_h"];

private _plate = _display ctrlCreate ["RscText", -1];
_plate ctrlSetPosition [_x + 0.03 * safezoneW, _y + 0.055 * safezoneH, _w * 0.62, _h - 0.08 * safezoneH];
_plate ctrlSetBackgroundColor [0.15, 0.18, 0.21, 1];
_plate ctrlCommit 0;

private _serviceLabel = _display ctrlCreate ["RscText", -1];
_serviceLabel ctrlSetPosition [_x + 0.05 * safezoneW, _y + 0.065 * safezoneH, _w * 0.22, 0.032 * safezoneH];
_serviceLabel ctrlSetText "TORQUE ACCESS // LIVE LOOM";
_serviceLabel ctrlSetTextColor [0.94, 0.78, 0.30, 1];
_serviceLabel ctrlSetFontHeight (0.016 * safezoneH);
_serviceLabel ctrlCommit 0;
private _loom = _display ctrlCreate ["RscText", -1];
_loom ctrlSetPosition [_x + 0.055 * safezoneW, _y + _h - 0.055 * safezoneH, _w * 0.54, 0.008 * safezoneH];
_loom ctrlSetBackgroundColor [0.72, 0.34, 0.12, 1];
_loom ctrlSetTooltip "Insulated maintenance wiring loom";
_loom ctrlCommit 0;
private _gauge = _display ctrlCreate ["RscText", -1];
_gauge ctrlSetPosition [_x + _w * 0.73, _y + 0.365 * safezoneH, _w * 0.20, 0.055 * safezoneH];
_gauge ctrlSetBackgroundColor [0.02, 0.03, 0.025, 1];
_gauge ctrlSetText "LOAD [NOMINAL]  |----^----|";
_gauge ctrlSetTextColor [0.72, 0.90, 0.66, 1];
_gauge ctrlSetFontHeight (0.016 * safezoneH);
_gauge ctrlCommit 0;

private _progress = [];
for "_i" from 0 to (_boltCount - 1) do { _progress pushBack 0; };
_display setVariable ["Waldo_MG_RP_Progress", _progress];
_display setVariable ["Waldo_MG_RP_Required", _turns * 20];
_display setVariable ["Waldo_MG_RP_Selected", -1];
_display setVariable ["Waldo_MG_RP_Mistakes", 0];
_display setVariable ["Waldo_MG_RP_MaxMistakes", _maxMistakes];
_display setVariable ["Waldo_MG_RP_Dragging", false];
_display setVariable ["Waldo_MG_RP_LastAngle", 0];
_display setVariable ["Waldo_MG_RP_DragSum", 0];

private _buttons = [];
private _cols = if (_boltCount <= 4) then {2} else {3};
private _rows = ceil (_boltCount / _cols);
private _bw = 0.12 * safezoneW;
private _bh = 0.085 * safezoneH;
private _gapX = ((_w * 0.62) - (_cols * _bw)) / (_cols + 1);
private _gapY = ((_h - 0.14 * safezoneH) - (_rows * _bh)) / (_rows + 1);
for "_i" from 0 to (_boltCount - 1) do {
    private _col = _i mod _cols;
    private _row = floor (_i / _cols);
    private _button = _display ctrlCreate ["RscButton", -1];
    _button ctrlSetPosition [_x + 0.03 * safezoneW + _gapX + _col * (_bw + _gapX), _y + 0.09 * safezoneH + _gapY + _row * (_bh + _gapY), _bw, _bh];
    _button ctrlSetText format ["BOLT %1  [LOOSE]  0%%", _i + 1];
    _button ctrlSetBackgroundColor [0.28, 0.31, 0.34, 1];
    _button ctrlSetTextColor [0.88, 0.90, 0.94, 1];
    _button ctrlSetTooltip "Select this bolt for tightening";
    _button setVariable ["Waldo_MG_RP_Index", _i];
    _button ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = ctrlParent _ctrl;
        if (_disp getVariable ["Waldo_MG_UI_Done", false]) exitWith {};
        private _index = _ctrl getVariable ["Waldo_MG_RP_Index", -1];
        private _progress = _disp getVariable ["Waldo_MG_RP_Progress", []];
        private _required = _disp getVariable ["Waldo_MG_RP_Required", 8];
        if ((_progress select _index) >= _required) exitWith {};
        _disp setVariable ["Waldo_MG_RP_Selected", _index];
        private _buttons = _disp getVariable ["Waldo_MG_RP_Buttons", []];
        {
            _x ctrlSetTextColor if (_forEachIndex == _index) then {[0.72, 0.94, 1, 1]} else {[0.88, 0.90, 0.94, 1]};
        } forEach _buttons;
        private _status = _disp getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
        if (!isNull _status) then { _status ctrlSetText format ["BOLT %1 SELECTED - DRAG THE WRENCH CLOCKWISE", _index + 1]; };
    }];
    _button ctrlCommit 0;
    _buttons pushBack _button;
};
_display setVariable ["Waldo_MG_RP_Buttons", _buttons];

private _toolButton = _display ctrlCreate ["RscButton", -1];
_toolButton ctrlSetPosition [_x + _w * 0.70, _y + 0.12 * safezoneH, _w * 0.25, 0.22 * safezoneH];
_toolButton ctrlSetText "CLOCKWISE TORQUE ARC";
_toolButton ctrlSetBackgroundColor [0.08, 0.12, 0.18, 1];
_toolButton ctrlSetTextColor [0.72, 0.94, 1, 1];
_toolButton ctrlSetTooltip "Hold the left mouse button and circle clockwise around the wrench";
_toolButton ctrlCommit 0;

private _wrench = _display ctrlCreate ["RscPicture", -1];
_wrench ctrlSetPosition [_x + _w * 0.755, _y + 0.155 * safezoneH, _w * 0.14, 0.12 * safezoneH];
_wrench ctrlSetText "\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\repair_ca.paa";
_wrench ctrlSetTextColor [0.72, 0.82, 0.94, 1];
_wrench ctrlCommit 0;
_display setVariable ["Waldo_MG_RP_Wrench", _wrench];

_toolButton ctrlAddEventHandler ["MouseButtonDown", {
    params ["_ctrl", "_button"];
    if (_button != 0) exitWith {};
    private _disp = ctrlParent _ctrl;
    if ((_disp getVariable ["Waldo_MG_RP_Selected", -1]) < 0) exitWith {};
    private _pos = ctrlPosition _ctrl;
    private _centre = [(_pos select 0) + (_pos select 2) / 2, (_pos select 1) + (_pos select 3) / 2];
    getMousePosition params ["_mouseX", "_mouseY"];
    _disp setVariable ["Waldo_MG_RP_Dragging", true];
    _disp setVariable ["Waldo_MG_RP_Centre", _centre];
    _disp setVariable ["Waldo_MG_RP_LastAngle", (_mouseY - (_centre select 1)) atan2 (_mouseX - (_centre select 0))];
}];
_display displayAddEventHandler ["MouseButtonUp", {
    params ["_disp", "_button"];
    if (_button == 0) then {_disp setVariable ["Waldo_MG_RP_Dragging", false];};
    false
}];
_display displayAddEventHandler ["MouseMoving", {
    params ["_disp"];
    if !(_disp getVariable ["Waldo_MG_RP_Dragging", false]) exitWith {false};
    getMousePosition params ["_mouseX", "_mouseY"];
    private _centre = _disp getVariable ["Waldo_MG_RP_Centre", [0.5, 0.5]];
    private _angle = (_mouseY - (_centre select 1)) atan2 (_mouseX - (_centre select 0));
    private _last = _disp getVariable ["Waldo_MG_RP_LastAngle", _angle];
    private _delta = _angle - _last;
    if (_delta > 180) then {_delta = _delta - 360;};
    if (_delta < -180) then {_delta = _delta + 360;};
    _disp setVariable ["Waldo_MG_RP_LastAngle", _angle];
    private _sum = (_disp getVariable ["Waldo_MG_RP_DragSum", 0]) + _delta;
    if (_sum < -15) then {
        _sum = 0;
        private _mistakes = (_disp getVariable ["Waldo_MG_RP_Mistakes", 0]) + 1;
        _disp setVariable ["Waldo_MG_RP_Mistakes", _mistakes];
        private _status = _disp getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
        if (!isNull _status) then { _status ctrlSetText format ["WRONG DIRECTION - MISTAKES %1 / %2", _mistakes, _disp getVariable ["Waldo_MG_RP_MaxMistakes", 3]]; };
        if (_mistakes > (_disp getVariable ["Waldo_MG_RP_MaxMistakes", 3])) then {
            [_disp, false, "TOOL SLIPPED"] call (_disp getVariable ["Waldo_MG_UI_Finish", {}]);
        };
    };
    if (_sum > 18) then {
        _sum = 0;
        private _index = _disp getVariable ["Waldo_MG_RP_Selected", -1];
        private _progress = _disp getVariable ["Waldo_MG_RP_Progress", []];
        private _required = _disp getVariable ["Waldo_MG_RP_Required", 8];
        if ((_progress select _index) >= _required) exitWith {
            _disp setVariable ["Waldo_MG_RP_DragSum", 0];
            _disp setVariable ["Waldo_MG_RP_Dragging", false];
            _disp setVariable ["Waldo_MG_RP_Selected", -1];
            private _mistakes = (_disp getVariable ["Waldo_MG_RP_Mistakes", 0]) + 1;
            _disp setVariable ["Waldo_MG_RP_Mistakes", _mistakes];
            private _status = _disp getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
            if (!isNull _status) then { _status ctrlSetText format ["BOLT OVER-TORQUED - MISTAKES %1 / %2", _mistakes, _disp getVariable ["Waldo_MG_RP_MaxMistakes", 3]]; };
            if (_mistakes > (_disp getVariable ["Waldo_MG_RP_MaxMistakes", 3])) then {
                [_disp, false, "THREADS STRIPPED"] call (_disp getVariable ["Waldo_MG_UI_Finish", {}]);
            };
        };
        private _value = ((_progress select _index) + 1) min _required;
        _progress set [_index, _value];
        _disp setVariable ["Waldo_MG_RP_Progress", _progress];
        private _buttons = _disp getVariable ["Waldo_MG_RP_Buttons", []];
        private _pct = round (100 * _value / _required);
        (_buttons select _index) ctrlSetText format ["BOLT %1  [%2]  %3%%", _index + 1, if (_value >= _required) then {"TORQUED"} else {"TIGHTENING"}, _pct];
        (_buttons select _index) ctrlSetBackgroundColor if (_value >= _required) then {[0.10, 0.34, 0.16, 1]} else {[0.22, 0.32, 0.44, 1]};
        private _wrench = _disp getVariable ["Waldo_MG_RP_Wrench", controlNull];
        if (!isNull _wrench) then { _wrench ctrlSetAngle [(_value * 360 / _required) mod 360, 0.5, 0.5]; };
        private _complete = {_x >= _required} count _progress;
        private _status = _disp getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
        if (!isNull _status) then { _status ctrlSetText format ["BOLTS TORQUED  %1 / %2", _complete, count _progress]; };
        if (_complete >= count _progress) then {
            [_disp, true, "ALL BOLTS TORQUED"] call (_disp getVariable ["Waldo_MG_UI_Finish", {}]);
        };
    };
    _disp setVariable ["Waldo_MG_RP_DragSum", _sum];
    false
}];
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

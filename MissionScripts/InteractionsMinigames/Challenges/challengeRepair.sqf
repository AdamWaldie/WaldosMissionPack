/*
 * Maintenance-hatch calibrated torque procedure.
 * Config remains [boltCount(3..6), precisionLevel(1..4), maxMistakes, timeLimit, title].
 * The former turnsRequired position now controls wrench tolerance without breaking callers.
 */
disableSerialization;
params [["_config", []], ["_resolve", {}]];
_config params [["_boltCount", 4], ["_precision", 2], ["_maxMistakes", 3], ["_timeLimit", 30], ["_title", "MAINTENANCE HATCH"]];
_boltCount = ((round _boltCount) max 3) min 6;
_precision = ((round _precision) max 1) min 4;
_maxMistakes = (round _maxMistakes) max 0;
private _tolerance = [5, 3, 2, 1] select (_precision - 1);

private _display = [
    _title,
    "Calibrate the torque wrench to each bolt's engraved specification, then apply it.",
    _timeLimit,
    _resolve,
    0.49,
    "Select bolt; adjust wrench with buttons, wheel or arrows; Space/APPLY TORQUE",
    format ["Every bolt has a TARGET value. Set the wrench within +/-%1 Nm, then apply it. An incorrect setting records a mistake.", _tolerance]
] call Waldo_fnc_MiniGameChallengeUI;
if (isNull _display) exitWith {};

private _targetPool = [30,35,40,45,50,55,60,65,70,75];
private _targets = [];
for "_index" from 0 to (_boltCount - 1) do {
    private _pick = floor random count _targetPool;
    _targets pushBack (_targetPool deleteAt _pick);
};
_display setVariable ["Waldo_MG_RP_Targets", _targets];
_display setVariable ["Waldo_MG_RP_Selected", -1];
_display setVariable ["Waldo_MG_RP_Setting", 30];
_display setVariable ["Waldo_MG_RP_Complete", []];
_display setVariable ["Waldo_MG_RP_Mistakes", 0];
_display setVariable ["Waldo_MG_RP_MaxMistakes", _maxMistakes];
_display setVariable ["Waldo_MG_RP_Tolerance", _tolerance];

private _hatch = [_display, "RscText", [1.7, 3, 26.6, 20], "opened calibrated maintenance hatch"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_hatch ctrlSetBackgroundColor [0.13, 0.15, 0.15, 1];
private _plate = [_display, "RscText", [2.6, 4, 24.8, 18], "maintenance access plate"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_plate ctrlSetBackgroundColor [0.19, 0.205, 0.20, 1];
private _procedure = [_display, "RscText", [3.4, 4.7, 23.2, 1.45], "maintenance calibration steps"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_procedure ctrlSetText "1 SELECT BOLT  >  2 MATCH TARGET Nm  >  3 APPLY TORQUE";
_procedure ctrlSetTextColor [0.96, 0.78, 0.30, 1];
_procedure ctrlSetBackgroundColor [0.035, 0.045, 0.04, 1];

private _complete = [];
private _bolts = [];
private _rings = [];
private _positions = [];
private _columns = if (_boltCount <= 4) then {2} else {3};
private _rows = ceil (_boltCount / _columns);
for "_index" from 0 to (_boltCount - 1) do {
    private _column = _index mod _columns;
    private _row = floor (_index / _columns);
    private _centreX = if (_columns == 2) then {8.8 + (_column * 12.4)} else {6.6 + (_column * 8.2)};
    private _centreY = if (_rows == 2) then {10 + (_row * 7.2)} else {8.5 + (_row * 5.4)};
    _positions pushBack [_centreX, _centreY];
    _complete pushBack false;
    private _ring = [];
    for "_segment" from 0 to 7 do {
        private _angle = _segment * 45;
        private _marker = [_display, "RscText", [_centreX + (2.5 * sin _angle) - 0.23, _centreY - (2.5 * cos _angle) - 0.23, 0.46, 0.46], format ["bolt %1 calibration ring segment %2", _index + 1, _segment + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
        _marker ctrlSetBackgroundColor [0.28, 0.30, 0.27, 1];
        _ring pushBack _marker;
    };
    _rings pushBack _ring;
    private _bolt = [_display, "RscButton", [_centreX - 2.4, _centreY - 1.65, 4.8, 3.3], format ["bolt %1 target %2 newton metres", _index + 1, _targets select _index]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _bolt ctrlSetText format ["B%1  //  TARGET %2 Nm", _index + 1, _targets select _index];
    _bolt ctrlSetBackgroundColor [0.39, 0.40, 0.36, 1];
    _bolt ctrlSetTextColor [1, 1, 0.94, 1];
    _bolt ctrlSetTooltip format ["Select bolt %1; required torque is %2 Nm", _index + 1, _targets select _index];
    _bolt setVariable ["Waldo_MG_RP_Index", _index];
    _bolt ctrlAddEventHandler ["ButtonClick", {
        private _control = _this select 0;
        private _display = ctrlParent _control;
        [_display, _control getVariable ["Waldo_MG_RP_Index", -1]] call (_display getVariable ["Waldo_MG_RP_SelectBolt", {}]);
    }];
    _bolts pushBack _bolt;
};
_display setVariable ["Waldo_MG_RP_Complete", _complete];
_display setVariable ["Waldo_MG_RP_BoltButtons", _bolts];
_display setVariable ["Waldo_MG_RP_Rings", _rings];
_display setVariable ["Waldo_MG_RP_BoltPositions", _positions];

// Decorative service wiring remains behind the procedure, not over its controls.
[_display, [[3.8, 20.6], [8, 19.6], [13, 20.8], [18, 19.5], [26, 20.6]], [0.70, 0.35, 0.16, 1], 0.20, "maintenance wiring loom orange"] call Waldo_fnc_MiniGameEquipmentPolyline;
[_display, [[3.8, 21.3], [9, 20.4], [14, 21.5], [20, 20.3], [26, 21.3]], [0.30, 0.52, 0.66, 1], 0.18, "maintenance wiring loom blue"] call Waldo_fnc_MiniGameEquipmentPolyline;

private _bay = [_display, "RscText", [29, 3, 9, 20], "calibrated torque wrench instrument bay"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_bay ctrlSetBackgroundColor [0.045, 0.055, 0.052, 1];
private _targetReadout = [_display, "RscText", [29.7, 4, 7.6, 2.3], "selected bolt target torque"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_targetReadout ctrlSetText "STEP 1 // SELECT BOLT";
_targetReadout ctrlSetBackgroundColor [0.01, 0.025, 0.018, 1];
_targetReadout ctrlSetTextColor [0.62, 0.92, 0.68, 1];
[_targetReadout, 0.032, 0.016] call Waldo_fnc_MiniGameEquipmentFitText;
_display setVariable ["Waldo_MG_RP_TargetReadout", _targetReadout];
private _settingReadout = [_display, "RscText", [29.7, 6.65, 7.6, 2.65], "torque wrench calibration readout"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_settingReadout ctrlSetText "WRENCH // 30 Nm";
_settingReadout ctrlSetBackgroundColor [0.015, 0.035, 0.025, 1];
_settingReadout ctrlSetTextColor [0.96, 0.78, 0.30, 1];
_settingReadout ctrlSetFontHeight 0.034;
[_settingReadout, 0.034, 0.016] call Waldo_fnc_MiniGameEquipmentFitText;
_display setVariable ["Waldo_MG_RP_SettingReadout", _settingReadout];

private _track = [_display, "RscText", [30, 9.8, 7, 0.55], "torque wrench scale"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_track ctrlSetBackgroundColor [0.20, 0.23, 0.21, 1];
private _targetMarker = [_display, "RscText", [30, 9.45, 0.32, 1.25], "selected target torque marker"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_targetMarker ctrlSetBackgroundColor [0.30, 0.78, 0.44, 1];
_targetMarker ctrlShow false;
private _settingMarker = [_display, "RscText", [31.1, 9.35, 0.38, 1.45], "wrench setting marker"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_settingMarker ctrlSetBackgroundColor [0.96, 0.76, 0.24, 1];
_display setVariable ["Waldo_MG_RP_TargetMarker", _targetMarker];
_display setVariable ["Waldo_MG_RP_SettingMarker", _settingMarker];

private _adjustments = [[-5, "-5"], [-1, "-1"], [1, "+1"], [5, "+5"]];
private _adjustButtons = [];
{
    private _button = [_display, "RscButton", [29.7 + (_forEachIndex * 1.95), 11.2, 1.72, 1.65], format ["adjust torque wrench %1 newton metres", _x select 0]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _button ctrlSetText (_x select 1);
    _button setVariable ["Waldo_MG_RP_Delta", _x select 0];
    _button ctrlAddEventHandler ["ButtonClick", {
        private _control = _this select 0;
        [(ctrlParent _control), _control getVariable ["Waldo_MG_RP_Delta", 0]] call ((ctrlParent _control) getVariable ["Waldo_MG_RP_Adjust", {}]);
    }];
    _adjustButtons pushBack _button;
} forEach _adjustments;
_display setVariable ["Waldo_MG_RP_AdjustButtons", _adjustButtons];
private _apply = [_display, "RscButton", [29.7, 13.25, 7.6, 3.1], "apply calibrated torque wrench"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_apply ctrlSetText "APPLY TORQUE [SPACE]";
_apply ctrlSetBackgroundColor [0.22, 0.20, 0.10, 1];
_apply ctrlEnable false;
_display setVariable ["Waldo_MG_RP_ApplyButton", _apply];
private _legend = [_display, "RscStructuredText", [29.8, 16.8, 7.4, 4.8], "torque wrench tolerance legend"] call Waldo_fnc_MiniGameEquipmentCreateControl;
private _legendTemplate = "<t size='%1' align='center' color='#EEE9D8'>CALIBRATION LIMIT</t><br/><t align='center' color='#7FD59B'>[OK] TARGET +/-"
    + str _tolerance
    + " Nm</t><br/><t align='center' color='#F2BE55'>YELLOW = WRENCH</t><br/><t align='center' color='#7FD59B'>GREEN = TARGET</t>";
[_legend, _legendTemplate, 1, 0.58] call Waldo_fnc_MiniGameEquipmentFitStructuredText;

_display setVariable ["Waldo_MG_RP_Refresh", {
    params ["_display"];
    private _selected = _display getVariable ["Waldo_MG_RP_Selected", -1];
    private _setting = _display getVariable ["Waldo_MG_RP_Setting", 30];
    private _targets = _display getVariable ["Waldo_MG_RP_Targets", []];
    private _target = if (_selected >= 0) then {_targets select _selected} else {-1};
    private _tolerance = _display getVariable ["Waldo_MG_RP_Tolerance", 3];
    private _settingReadout = _display getVariable ["Waldo_MG_RP_SettingReadout", controlNull];
    if (!isNull _settingReadout) then {
        private _matched = _selected >= 0 && {abs (_setting - _target) <= _tolerance};
        _settingReadout ctrlSetText format ["WRENCH // %1 Nm // %2", _setting, if (_selected < 0) then {"SELECT BOLT"} else {if (_matched) then {"[OK] MATCH"} else {if (_setting < _target) then {"LOW"} else {"HIGH"}}}];
        _settingReadout ctrlSetTextColor (if (_matched) then {[0.55, 1, 0.65, 1]} else {[0.96, 0.78, 0.30, 1]});
        [_settingReadout, 0.034, 0.016] call Waldo_fnc_MiniGameEquipmentFitText;
    };
    private _settingMarker = _display getVariable ["Waldo_MG_RP_SettingMarker", controlNull];
    if (!isNull _settingMarker) then {[_display, _settingMarker, [30 + (7 * ((_setting - 20) / 60)) - 0.19, 9.35, 0.38, 1.45], 0] call Waldo_fnc_MiniGameEquipmentSetPosition;};
    private _targetMarker = _display getVariable ["Waldo_MG_RP_TargetMarker", controlNull];
    if (!isNull _targetMarker) then {
        _targetMarker ctrlShow (_selected >= 0);
        if (_selected >= 0) then {[_display, _targetMarker, [30 + (7 * ((_target - 20) / 60)) - 0.16, 9.45, 0.32, 1.25], 0] call Waldo_fnc_MiniGameEquipmentSetPosition;};
    };
    private _apply = _display getVariable ["Waldo_MG_RP_ApplyButton", controlNull];
    if (!isNull _apply) then {_apply ctrlEnable (_selected >= 0);};
}];

_display setVariable ["Waldo_MG_RP_SelectBolt", {
    params ["_display", "_index"];
    if (!(_display getVariable ["Waldo_IMG_Started", false]) || {_display getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
    private _complete = _display getVariable ["Waldo_MG_RP_Complete", []];
    if (_index < 0 || {_complete param [_index, false]}) exitWith {};
    _display setVariable ["Waldo_MG_RP_Selected", _index];
    private _target = (_display getVariable ["Waldo_MG_RP_Targets", []]) select _index;
    private _readout = _display getVariable ["Waldo_MG_RP_TargetReadout", controlNull];
    if (!isNull _readout) then {
        _readout ctrlSetText format ["BOLT %1 TARGET // %2 Nm", _index + 1, _target];
        [_readout, 0.032, 0.016] call Waldo_fnc_MiniGameEquipmentFitText;
    };
    {
        if (!(_complete param [_forEachIndex, false])) then {
            _x ctrlSetBackgroundColor (if (_forEachIndex == _index) then {[0.76, 0.60, 0.16, 1]} else {[0.39, 0.40, 0.36, 1]});
            _x ctrlSetTextColor (if (_forEachIndex == _index) then {[0.04, 0.05, 0.04, 1]} else {[1, 1, 0.94, 1]});
        };
    } forEach (_display getVariable ["Waldo_MG_RP_BoltButtons", []]);
    private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then {_status ctrlSetText format ["[STEP 2/3] BOLT %1 REQUIRES %2 Nm // CALIBRATE WRENCH", _index + 1, _target];};
    [_display] call (_display getVariable ["Waldo_MG_RP_Refresh", {}]);
}];

_display setVariable ["Waldo_MG_RP_Adjust", {
    params ["_display", "_delta"];
    if (!(_display getVariable ["Waldo_IMG_Started", false]) || {_display getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
    private _setting = ((_display getVariable ["Waldo_MG_RP_Setting", 30]) + _delta) max 20 min 80;
    _display setVariable ["Waldo_MG_RP_Setting", _setting];
    [_display] call (_display getVariable ["Waldo_MG_RP_Refresh", {}]);
}];

_display setVariable ["Waldo_MG_RP_Apply", {
    params ["_display"];
    if (!(_display getVariable ["Waldo_IMG_Started", false]) || {_display getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
    private _index = _display getVariable ["Waldo_MG_RP_Selected", -1];
    if (_index < 0) exitWith {};
    private _setting = _display getVariable ["Waldo_MG_RP_Setting", 30];
    private _target = (_display getVariable ["Waldo_MG_RP_Targets", []]) select _index;
    private _tolerance = _display getVariable ["Waldo_MG_RP_Tolerance", 3];
    if (abs (_setting - _target) > _tolerance) exitWith {
        private _mistakes = (_display getVariable ["Waldo_MG_RP_Mistakes", 0]) + 1;
        _display setVariable ["Waldo_MG_RP_Mistakes", _mistakes];
        private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
        if (!isNull _status) then {_status ctrlSetText format ["[X] WRENCH %1 Nm IS %2 FOR BOLT %3 (%4 Nm) // MISTAKE %5/%6", _setting, if (_setting < _target) then {"LOW"} else {"HIGH"}, _index + 1, _target, _mistakes, _display getVariable ["Waldo_MG_RP_MaxMistakes", 0]];};
        if (_mistakes >= ((_display getVariable ["Waldo_MG_RP_MaxMistakes", 0]) max 1)) then {[_display, false, "[X] FASTENER OR THREAD DAMAGED"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);};
    };
    private _complete = _display getVariable ["Waldo_MG_RP_Complete", []];
    _complete set [_index, true];
    _display setVariable ["Waldo_MG_RP_Complete", _complete];
    private _button = (_display getVariable ["Waldo_MG_RP_BoltButtons", []]) select _index;
    _button ctrlSetText format ["B%1 // [OK] %2 Nm", _index + 1, _target];
    _button ctrlSetBackgroundColor [0.13, 0.40, 0.23, 1];
    _button ctrlSetTextColor [0.9, 1, 0.9, 1];
    _button ctrlEnable false;
    { _x ctrlSetBackgroundColor [0.30, 0.78, 0.44, 1]; } forEach ((_display getVariable ["Waldo_MG_RP_Rings", []]) select _index);
    _display setVariable ["Waldo_MG_RP_Selected", -1];
    private _readout = _display getVariable ["Waldo_MG_RP_TargetReadout", controlNull];
    if (!isNull _readout) then {
        _readout ctrlSetText format ["BOLT %1 // [OK] TORQUED", _index + 1];
        [_readout, 0.032, 0.016] call Waldo_fnc_MiniGameEquipmentFitText;
    };
    if ({_x} count _complete >= count _complete) exitWith {[_display, true, "[OK] ACCESS PLATE TORQUED TO SPECIFICATION"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);};
    private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then {_status ctrlSetText "[OK] BOLT SEATED // SELECT NEXT ENGRAVED TARGET";};
    [_display] call (_display getVariable ["Waldo_MG_RP_Refresh", {}]);
}];

_apply ctrlAddEventHandler ["ButtonClick", {[(ctrlParent (_this select 0))] call ((ctrlParent (_this select 0)) getVariable ["Waldo_MG_RP_Apply", {}]);}];
[_display, "KeyDown", {
    params ["_display", "_key"];
    if (_key == 203) exitWith {[_display, -1] call (_display getVariable ["Waldo_MG_RP_Adjust", {}]); true};
    if (_key == 205) exitWith {[_display, 1] call (_display getVariable ["Waldo_MG_RP_Adjust", {}]); true};
    if (_key == 208) exitWith {[_display, -5] call (_display getVariable ["Waldo_MG_RP_Adjust", {}]); true};
    if (_key == 200) exitWith {[_display, 5] call (_display getVariable ["Waldo_MG_RP_Adjust", {}]); true};
    if (_key == 57) exitWith {[_display] call (_display getVariable ["Waldo_MG_RP_Apply", {}]); true};
    false
}] call Waldo_fnc_MiniGameEquipmentAddDisplayHandler;
[_display, "MouseZChanged", {
    params ["_display", "_scroll"];
    [_display, if (_scroll > 0) then {1} else {-1}] call (_display getVariable ["Waldo_MG_RP_Adjust", {}]);
    true
}] call Waldo_fnc_MiniGameEquipmentAddDisplayHandler;

[_display] call (_display getVariable ["Waldo_MG_RP_Refresh", {}]);
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

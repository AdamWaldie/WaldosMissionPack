/*
 * NATO communications receiver tuning procedure.
 * Config: [channels(1..5), tolerance(0.02..0.15), holdTime, timeLimit, title]
 */
disableSerialization;
params [["_config", []], ["_resolve", {}]];
_config params [["_channels", 3], ["_tolerance", 0.05], ["_holdTime", 1], ["_timeLimit", 30], ["_title", "COMMUNICATIONS UNIT"]];
_channels = ((round _channels) max 1) min 5;
_tolerance = (_tolerance max 0.02) min 0.15;
_holdTime = _holdTime max 0.2;

private _display = [
    _title,
    "Tune each assigned channel into the marked carrier band and hold the signal steady.",
    _timeLimit,
    _resolve,
    0.45,
    "Mouse wheel over dial, TUNE -/+, or Left/Right arrows",
    "Use the scope trace, numeric frequency and LOCK caption together; colour is supplementary."
] call Waldo_fnc_MiniGameChallengeUI;
if (isNull _display) exitWith {};

private _initial = random 1;
private _target = 0.15 + random 0.7;
if (abs (_initial - _target) <= _tolerance) then {_initial = (_target + 0.28) min 1;};
_display setVariable ["Waldo_MG_RT_Value", _initial];
_display setVariable ["Waldo_MG_RT_Target", _target];
_display setVariable ["Waldo_MG_RT_Channel", 1];
_display setVariable ["Waldo_MG_RT_Channels", _channels];
_display setVariable ["Waldo_MG_RT_Tolerance", _tolerance];
_display setVariable ["Waldo_MG_RT_HoldTime", _holdTime];
_display setVariable ["Waldo_MG_RT_HoldStart", -1];

private _receiver = [_display, "RscText", [2, 3, 36, 20], "NATO communications receiver casing"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_receiver ctrlSetBackgroundColor [0.11, 0.14, 0.13, 1];
private _scopeFrame = [_display, "RscText", [3.5, 4.2, 23, 10.5], "oscilloscope bezel"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_scopeFrame ctrlSetBackgroundColor [0.025, 0.035, 0.03, 1];
private _scope = [_display, "RscText", [4.4, 5.1, 21.2, 8.7], "carrier oscilloscope"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_scope ctrlSetBackgroundColor [0.005, 0.018, 0.012, 1];
for "_gridX" from 0 to 6 do {
    [_display, [[4.8 + (_gridX * 3.35), 5.5], [4.8 + (_gridX * 3.35), 13.4]], [0.08, 0.20, 0.13, 0.75], 0.10, "oscilloscope vertical grid"] call Waldo_fnc_MiniGameEquipmentPolyline;
};
for "_gridY" from 0 to 3 do {
    [_display, [[4.8, 5.7 + (_gridY * 2.45)], [25.2, 5.7 + (_gridY * 2.45)]], [0.08, 0.20, 0.13, 0.75], 0.10, "oscilloscope horizontal grid"] call Waldo_fnc_MiniGameEquipmentPolyline;
};
// Create one stable trace. Recreating and deleting hundreds of small controls
// during tuning can leave multiple waveform generations painted in the same
// frame on Arma. These points are repositioned in place for the display lifetime.
private _waveformPoints = [];
for "_sample" from 0 to 60 do {
    private _point = [_display, "RscText", [5 + (_sample * (19.7 / 60)), 9.5, 0.18, 0.18], format ["live carrier waveform point %1", _sample + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _point ctrlSetBackgroundColor [0.35, 0.92, 0.48, 1];
    _waveformPoints pushBack _point;
};
_display setVariable ["Waldo_MG_RT_WaveformPoints", _waveformPoints];
private _frequency = [_display, "RscText", [4, 15.2, 22, 2.5], "frequency readout"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_frequency ctrlSetBackgroundColor [0.008, 0.018, 0.012, 1];
_frequency ctrlSetTextColor [0.55, 1, 0.65, 1];
_frequency ctrlSetFontHeight 0.036;
_display setVariable ["Waldo_MG_RT_Frequency", _frequency];
private _scale = [_display, "RscText", [4, 18.2, 22, 2], "frequency scale"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_scale ctrlSetText "30 MHz       45       60       75       90 MHz";
_scale ctrlSetTextColor [0.78, 0.80, 0.73, 1];
private _track = [_display, "RscText", [4.5, 20.3, 21, 0.7], "frequency tuning track"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_track ctrlSetBackgroundColor [0.18, 0.20, 0.18, 1];
private _targetBand = [_display, "RscText", [4.5, 20, 2, 1.3], "target carrier band"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_targetBand ctrlSetBackgroundColor [0.22, 0.55, 0.34, 0.78];
_targetBand ctrlSetText "TARGET";
_targetBand ctrlSetTextColor [1, 1, 1, 1];
_display setVariable ["Waldo_MG_RT_TargetBand", _targetBand];
private _needle = [_display, "RscText", [4.5, 19.8, 0.35, 1.7], "current frequency needle"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_needle ctrlSetBackgroundColor [0.95, 0.84, 0.34, 1];
_display setVariable ["Waldo_MG_RT_Needle", _needle];

private _dialBay = [_display, "RscText", [28, 4.2, 8.5, 12.5], "receiver tuning dial bay"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_dialBay ctrlSetBackgroundColor [0.04, 0.05, 0.045, 1];
private _dialCentre = [32.25, 10.2];
for "_tick" from 0 to 23 do {
    private _angle = _tick * 15;
    private _tickControl = [_display, "RscText", [
        (_dialCentre select 0) + (3.15 * sin _angle) - 0.16,
        (_dialCentre select 1) - (4.1 * cos _angle) - 0.16,
        0.32,
        0.32
    ], format ["tuning scale tick %1", _tick + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _tickControl ctrlSetBackgroundColor (if (_tick mod 3 == 0) then {[0.82, 0.78, 0.62, 1]} else {[0.38, 0.40, 0.36, 1]});
};
private _dial = [_display, "RscButton", [29.5, 7.1, 5.5, 6.2], "frequency tuning dial"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_dial ctrlSetText "TUNING DIAL";
_dial ctrlSetBackgroundColor [0.15, 0.18, 0.17, 1];
_dial ctrlSetTooltip "Hold and rotate the pointer around the dial, or use the mouse wheel";
private _dialMarker = [_display, "RscText", [32, 6.1, 0.5, 1], "tuning dial position marker"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_dialMarker ctrlSetBackgroundColor [0.96, 0.78, 0.30, 1];
_display setVariable ["Waldo_MG_RT_DialMarker", _dialMarker];
private _minus = [_display, "RscButton", [28.6, 17.5, 3.7, 3], "tune frequency down"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_minus ctrlSetText "TUNE -";
private _plus = [_display, "RscButton", [32.7, 17.5, 3.7, 3], "tune frequency up"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_plus ctrlSetText "TUNE +";
private _lockLamp = [_display, "RscText", [28.6, 21, 7.8, 1.4], "carrier lock indicator"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_lockLamp ctrlSetText "[SEEK] NO LOCK";
_lockLamp ctrlSetBackgroundColor [0.20, 0.12, 0.05, 1];
_display setVariable ["Waldo_MG_RT_LockLamp", _lockLamp];

_display setVariable ["Waldo_MG_RT_Refresh", {
    params ["_display"];
    private _value = _display getVariable ["Waldo_MG_RT_Value", 0.5];
    private _target = _display getVariable ["Waldo_MG_RT_Target", 0.5];
    private _tolerance = _display getVariable ["Waldo_MG_RT_Tolerance", 0.05];
    [_display, _display getVariable ["Waldo_MG_RT_TargetBand", controlNull], [4.5 + (21 * ((_target - _tolerance) max 0)), 20, 21 * ((2 * _tolerance) min 1), 1.3], 0] call Waldo_fnc_MiniGameEquipmentSetPosition;
    [_display, _display getVariable ["Waldo_MG_RT_Needle", controlNull], [4.32 + (21 * _value), 19.8, 0.35, 1.7], 0] call Waldo_fnc_MiniGameEquipmentSetPosition;
    private _angle = -135 + (270 * _value);
    [_display, _display getVariable ["Waldo_MG_RT_DialMarker", controlNull], [32.25 + (2.5 * sin _angle) - 0.25, 10.2 - (3.2 * cos _angle) - 0.5, 0.5, 1], 0] call Waldo_fnc_MiniGameEquipmentSetPosition;
    private _frequency = _display getVariable ["Waldo_MG_RT_Frequency", controlNull];
    if (!isNull _frequency) then {_frequency ctrlSetText format ["CH %1/%2     %3 MHz", _display getVariable ["Waldo_MG_RT_Channel", 1], _display getVariable ["Waldo_MG_RT_Channels", 1], (30 + (60 * _value)) toFixed 2];};
    private _error = abs (_value - _target);
    private _amplitude = 0.45 + (2.4 * (1 - ((_error / 0.5) min 1)));
    {
        private _sample = _forEachIndex;
        private _sampleX = 5 + (_sample * (19.7 / 60));
        private _sampleY = 9.5 + (_amplitude * sin ((_sample * 27) + (_value * 120))) + (0.35 * sin (_sample * 10.5));
        [_display, _x, [_sampleX - 0.09, _sampleY - 0.09, 0.18, 0.18], 0] call Waldo_fnc_MiniGameEquipmentSetPosition;
    } forEach (_display getVariable ["Waldo_MG_RT_WaveformPoints", []]);
    private _locked = _error <= _tolerance;
    private _lamp = _display getVariable ["Waldo_MG_RT_LockLamp", controlNull];
    if (_locked) then {
        if ((_display getVariable ["Waldo_MG_RT_HoldStart", -1]) < 0) then {_display setVariable ["Waldo_MG_RT_HoldStart", time];};
        if (!isNull _lamp) then {_lamp ctrlSetText "[LOCK] CARRIER ACQUIRED"; _lamp ctrlSetBackgroundColor [0.12, 0.38, 0.20, 1];};
    } else {
        _display setVariable ["Waldo_MG_RT_HoldStart", -1];
        if (!isNull _lamp) then {_lamp ctrlSetText (if (_value < _target) then {"[SEEK >] TUNE HIGHER"} else {"[< SEEK] TUNE LOWER"}); _lamp ctrlSetBackgroundColor [0.20, 0.12, 0.05, 1];};
    };
    private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then {_status ctrlSetText format ["CHANNEL %1/%2 // %3", _display getVariable ["Waldo_MG_RT_Channel", 1], _display getVariable ["Waldo_MG_RT_Channels", 1], if (_locked) then {"[LOCK] HOLD STEADY"} else {if (_value < _target) then {"[SEEK >] INCREASE FREQUENCY"} else {"[< SEEK] DECREASE FREQUENCY"}}];};
}];
_display setVariable ["Waldo_MG_RT_Adjust", {
    params ["_display", "_delta"];
    if (_display getVariable ["Waldo_MG_UI_Done", false] || {!(_display getVariable ["Waldo_IMG_Started", false])}) exitWith {};
    _display setVariable ["Waldo_MG_RT_Value", (((_display getVariable ["Waldo_MG_RT_Value", 0.5]) + _delta) max 0) min 1];
    [_display] call (_display getVariable ["Waldo_MG_RT_Refresh", {}]);
}];
_minus ctrlAddEventHandler ["ButtonClick", {private _display = ctrlParent (_this select 0); [_display, -0.015] call (_display getVariable ["Waldo_MG_RT_Adjust", {}]);}];
_plus ctrlAddEventHandler ["ButtonClick", {private _display = ctrlParent (_this select 0); [_display, 0.015] call (_display getVariable ["Waldo_MG_RT_Adjust", {}]);}];
_dial ctrlAddEventHandler ["MouseZChanged", {params ["_control", "_change"]; private _display = ctrlParent _control; [_display, 0.008 * _change] call (_display getVariable ["Waldo_MG_RT_Adjust", {}]); true}];
[_display, "KeyDown", {
    params ["_display", "_key"];
    if (_key == 203) exitWith {[_display, -0.01] call (_display getVariable ["Waldo_MG_RT_Adjust", {}]); true};
    if (_key == 205) exitWith {[_display, 0.01] call (_display getVariable ["Waldo_MG_RT_Adjust", {}]); true};
    false
}] call Waldo_fnc_MiniGameEquipmentAddDisplayHandler;
[_display, _dial, {
    params ["_display", "_control", "_position", "_phase"];
    if (isNull _control) exitWith {};
    private _cell = _display getVariable ["Waldo_MG_UI_GridCell", [1, 1]];
    private _dx = ((_position select 0) - 32.25) * (_cell select 0);
    private _dy = ((_position select 1) - 10.2) * (_cell select 1);
    private _angle = _dy atan2 _dx;
    if (_phase == "START") exitWith {
        _display setVariable ["Waldo_MG_RT_DragAngle", _angle];
        private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
        if (!isNull _status) then {_status ctrlSetText "[TUNING] ROTATE DIAL // HOLD INSIDE TARGET BAND";};
    };
    if (_phase != "MOVE") exitWith {};
    private _last = _display getVariable ["Waldo_MG_RT_DragAngle", _angle];
    private _delta = _angle - _last;
    if (_delta > 180) then {_delta = _delta - 360;};
    if (_delta < -180) then {_delta = _delta + 360;};
    _display setVariable ["Waldo_MG_RT_DragAngle", _angle];
    if (abs _delta <= 60) then {
        [_display, _delta / 270] call (_display getVariable ["Waldo_MG_RT_Adjust", {}]);
    };
}] call Waldo_fnc_MiniGameEquipmentBindDrag;
[_display] call (_display getVariable ["Waldo_MG_RT_Refresh", {}]);

private _holdWorker = [_display] spawn {
    params ["_display"];
    waitUntil {isNull _display || {_display getVariable ["Waldo_IMG_Started", false]}};
    while {!isNull _display && {!(_display getVariable ["Waldo_MG_UI_Done", false])}} do {
        private _holdStart = _display getVariable ["Waldo_MG_RT_HoldStart", -1];
        if (_holdStart >= 0 && {(time - _holdStart) >= (_display getVariable ["Waldo_MG_RT_HoldTime", 1])}) then {
            private _channel = (_display getVariable ["Waldo_MG_RT_Channel", 1]) + 1;
            if (_channel > (_display getVariable ["Waldo_MG_RT_Channels", 1])) exitWith {
                [_display, true, "[OK] ALL CHANNELS LOCKED"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
            };
            _display setVariable ["Waldo_MG_RT_Channel", _channel];
            private _target = 0.15 + random 0.7;
            _display setVariable ["Waldo_MG_RT_Target", _target];
            _display setVariable ["Waldo_MG_RT_HoldStart", -1];
            [_display] call (_display getVariable ["Waldo_MG_RT_Refresh", {}]);
        };
        uiSleep 0.05;
    };
};
private _workers = _display getVariable ["Waldo_MG_UI_Workers", []];
_workers pushBack _holdWorker;
_display setVariable ["Waldo_MG_UI_Workers", _workers];
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

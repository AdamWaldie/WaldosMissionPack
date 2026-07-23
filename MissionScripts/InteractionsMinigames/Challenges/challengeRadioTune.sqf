/*
 * Author: Waldo
 * Radio-tuning interaction challenge. Tune a dial to successive target frequencies and hold
 * the signal inside tolerance long enough to lock each channel.
 *
 * Arguments:
 * _config  - Array - [channels(1..5), tolerance(0.02..0.15), holdTime, timeLimit, title]
 * _resolve - Code  - called once with boolean success and typed outcome metadata
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [[3, 0.05, 1, 30, "SIGNAL TUNING"], {}] call Waldo_fnc_MiniGameRadioTune;
 */

disableSerialization;
params [["_config", []], ["_resolve", {}]];
_config params [["_channels", 3], ["_tolerance", 0.05], ["_holdTime", 1], ["_timeLimit", 30], ["_title", "COMMUNICATIONS UNIT"]];
_channels = ((round _channels) max 1) min 5;
_tolerance = (_tolerance max 0.02) min 0.15;
_holdTime = _holdTime max 0.2;

private _display = [_title, "Tune the receiver into the highlighted frequency and hold the signal steady.", _timeLimit, _resolve, 0.42, "Mouse wheel or Left/Right: tune frequency", "Align the needle with the labelled TARGET band. Fine adjustments are easier with the arrow keys."] call Waldo_fnc_MiniGameChallengeUI;
if (isNull _display) exitWith {};
private _content = _display getVariable ["Waldo_MG_UI_Content", []];
_content params ["_x", "_y", "_w"];

_display setVariable ["Waldo_MG_RT_Value", random 1];
_display setVariable ["Waldo_MG_RT_Target", 0.15 + random 0.7];
_display setVariable ["Waldo_MG_RT_Channel", 1];
_display setVariable ["Waldo_MG_RT_Channels", _channels];
_display setVariable ["Waldo_MG_RT_Tolerance", _tolerance];
_display setVariable ["Waldo_MG_RT_HoldTime", _holdTime];
_display setVariable ["Waldo_MG_RT_HoldStart", -1];

private _scope = _display ctrlCreate ["RscText", -1];
_scope ctrlSetPosition [_x + 0.06 * safezoneW, _y + 0.052 * safezoneH, _w - 0.12 * safezoneW, 0.045 * safezoneH];
_scope ctrlSetBackgroundColor [0.01, 0.025, 0.018, 1];
_scope ctrlSetText "OSCILLOSCOPE  //  CARRIER RESPONSE    _/\/\__/\/\_";
_scope ctrlSetTextColor [0.42, 0.88, 0.50, 1];
_scope ctrlSetFontHeight (0.016 * safezoneH);
_scope ctrlCommit 0;

private _scale = _display ctrlCreate ["RscText", -1];
_scale ctrlSetPosition [_x + 0.06 * safezoneW, _y + 0.11 * safezoneH, _w - 0.12 * safezoneW, 0.07 * safezoneH];
_scale ctrlSetBackgroundColor [0.02, 0.03, 0.04, 1];
_scale ctrlSetText "30 MHz                         60 MHz                         90 MHz";
_scale ctrlSetTextColor [0.62, 0.72, 0.82, 1];
_scale ctrlCommit 0;

private _target = _display ctrlCreate ["RscText", -1];
_target ctrlSetBackgroundColor [0.22, 0.62, 0.30, 0.55];
_target ctrlSetText "TARGET";
_target ctrlSetTextColor [0.92, 0.98, 0.90, 1];
_target ctrlSetFontHeight (0.012 * safezoneH);
_target ctrlCommit 0;
_display setVariable ["Waldo_MG_RT_TargetCtrl", _target];

private _needle = _display ctrlCreate ["RscText", -1];
_needle ctrlSetBackgroundColor [0.72, 0.94, 1, 1];
_needle ctrlCommit 0;
_display setVariable ["Waldo_MG_RT_NeedleCtrl", _needle];

private _readout = _display ctrlCreate ["RscText", -1];
_readout ctrlSetPosition [_x + _w * 0.25, _y + 0.205 * safezoneH, _w * 0.5, 0.055 * safezoneH];
_readout ctrlSetBackgroundColor [0.01, 0.02, 0.025, 1];
_readout ctrlSetTextColor [0.55, 1, 0.65, 1];
_readout ctrlSetFontHeight (0.032 * safezoneH);
_readout ctrlCommit 0;
_display setVariable ["Waldo_MG_RT_Readout", _readout];

private _minus = _display ctrlCreate ["RscButton", -1];
_minus ctrlSetPosition [_x + _w * 0.20, _y + 0.29 * safezoneH, _w * 0.18, 0.06 * safezoneH];
_minus ctrlSetText "TUNE -";
_minus ctrlCommit 0;
private _dial = _display ctrlCreate ["RscButton", -1];
_dial ctrlSetPosition [_x + _w * 0.41, _y + 0.275 * safezoneH, _w * 0.18, 0.09 * safezoneH];
_dial ctrlSetText "TUNING DIAL";
_dial ctrlSetBackgroundColor [0.10, 0.19, 0.40, 1];
_dial ctrlSetTooltip "Use the mouse wheel while pointing here";
_dial ctrlCommit 0;
private _plus = _display ctrlCreate ["RscButton", -1];
_plus ctrlSetPosition [_x + _w * 0.62, _y + 0.29 * safezoneH, _w * 0.18, 0.06 * safezoneH];
_plus ctrlSetText "TUNE +";
_plus ctrlCommit 0;

_display setVariable ["Waldo_MG_RT_Refresh", {
    params ["_disp"];
    private _content = _disp getVariable ["Waldo_MG_UI_Content", []];
    _content params ["_x", "_y", "_w"];
    private _value = _disp getVariable ["Waldo_MG_RT_Value", 0.5];
    private _target = _disp getVariable ["Waldo_MG_RT_Target", 0.5];
    private _tol = _disp getVariable ["Waldo_MG_RT_Tolerance", 0.05];
    private _trackX = _x + 0.06 * safezoneW;
    private _trackW = _w - 0.12 * safezoneW;
    private _targetCtrl = _disp getVariable ["Waldo_MG_RT_TargetCtrl", controlNull];
    private _needle = _disp getVariable ["Waldo_MG_RT_NeedleCtrl", controlNull];
    if (!isNull _targetCtrl) then { _targetCtrl ctrlSetPosition [_trackX + ((_target - _tol) max 0) * _trackW, _y + 0.11 * safezoneH, (2 * _tol min 1) * _trackW, 0.07 * safezoneH]; _targetCtrl ctrlCommit 0; };
    if (!isNull _needle) then { _needle ctrlSetPosition [_trackX + _value * _trackW - 0.002 * safezoneW, _y + 0.10 * safezoneH, 0.004 * safezoneW, 0.09 * safezoneH]; _needle ctrlCommit 0; };
    private _readout = _disp getVariable ["Waldo_MG_RT_Readout", controlNull];
    if (!isNull _readout) then { _readout ctrlSetText format ["%1 MHz", (30 + _value * 60) toFixed 2]; };
    private _locked = abs (_value - _target) <= _tol;
    if (_locked) then {
        if ((_disp getVariable ["Waldo_MG_RT_HoldStart", -1]) < 0) then { _disp setVariable ["Waldo_MG_RT_HoldStart", time]; };
    } else {
        _disp setVariable ["Waldo_MG_RT_HoldStart", -1];
    };
    private _status = _disp getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then { _status ctrlSetText format ["CHANNEL %1 / %2  //  %3", _disp getVariable ["Waldo_MG_RT_Channel", 1], _disp getVariable ["Waldo_MG_RT_Channels", 1], if (_locked) then {"[LOCK] SIGNAL ACQUIRED - HOLD"} else {"[SEEK] ALIGN NEEDLE WITH TARGET BAND"}]; };
}];
_display setVariable ["Waldo_MG_RT_Adjust", {
    params ["_disp", "_delta"];
    if (_disp getVariable ["Waldo_MG_UI_Done", false] || {!(_disp getVariable ["Waldo_IMG_Started", false])}) exitWith {};
    _disp setVariable ["Waldo_MG_RT_Value", (((_disp getVariable ["Waldo_MG_RT_Value", 0.5]) + _delta) max 0) min 1];
    [_disp] call (_disp getVariable ["Waldo_MG_RT_Refresh", {}]);
}];
_minus ctrlAddEventHandler ["ButtonClick", { [ctrlParent (_this select 0), -0.025] call ((ctrlParent (_this select 0)) getVariable ["Waldo_MG_RT_Adjust", {}]); }];
_plus ctrlAddEventHandler ["ButtonClick", { [ctrlParent (_this select 0), 0.025] call ((ctrlParent (_this select 0)) getVariable ["Waldo_MG_RT_Adjust", {}]); }];
_dial ctrlAddEventHandler ["MouseZChanged", { params ["_ctrl", "_change"]; private _disp = ctrlParent _ctrl; [_disp, 0.01 * _change] call (_disp getVariable ["Waldo_MG_RT_Adjust", {}]); }];
_display displayAddEventHandler ["KeyDown", { params ["_disp", "_key"]; if (_key == 203) exitWith {[_disp, -0.02] call (_disp getVariable ["Waldo_MG_RT_Adjust", {}]); true}; if (_key == 205) exitWith {[_disp, 0.02] call (_disp getVariable ["Waldo_MG_RT_Adjust", {}]); true}; false }];
[_display] call (_display getVariable ["Waldo_MG_RT_Refresh", {}]);

[_display] spawn {
    params ["_disp"];
    waitUntil {isNull _disp || {_disp getVariable ["Waldo_IMG_Started", false]}};
    if (isNull _disp) exitWith {};
    if ((_disp getVariable ["Waldo_MG_RT_HoldStart", -1]) >= 0) then {_disp setVariable ["Waldo_MG_RT_HoldStart", time];};
    while {!isNull _disp && {!(_disp getVariable ["Waldo_MG_UI_Done", false])}} do {
        private _hold = _disp getVariable ["Waldo_MG_RT_HoldStart", -1];
        if (_hold >= 0 && {(time - _hold) >= (_disp getVariable ["Waldo_MG_RT_HoldTime", 1])}) then {
            private _channel = (_disp getVariable ["Waldo_MG_RT_Channel", 1]) + 1;
            if (_channel > (_disp getVariable ["Waldo_MG_RT_Channels", 1])) exitWith {
                [_disp, true, "ALL CHANNELS LOCKED"] call (_disp getVariable ["Waldo_MG_UI_Finish", {}]);
            };
            _disp setVariable ["Waldo_MG_RT_Channel", _channel];
            _disp setVariable ["Waldo_MG_RT_Target", 0.15 + random 0.7];
            _disp setVariable ["Waldo_MG_RT_HoldStart", -1];
            [_disp] call (_disp getVariable ["Waldo_MG_RT_Refresh", {}]);
        };
        sleep 0.05;
    };
};
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

/*
 * Author: Waldo
 * Lockpick mini game (a built-in interaction challenge), a timing/skill test. A marker sweeps
 * back and forth beneath an illustrated lock cylinder; press SET PIN (or Space) while it sits in the highlighted
 * sweet spot to set that pin. Set every pin to win; a miss, the clock running out, or Escape
 * fails. Each pin re-randomises the sweet spot and the sweep speeds up. Ideal for padlocks,
 * doors, containers and vehicles.
 *
 * Challenge opener following the [_config, _resolve] contract; dispatched by
 * Waldo_fnc_MiniGameChallenge.
 *
 * Arguments:
 * _config  - Array - challenge config, all optional:
 *              0: _pins      - Number - pins to set, clamped 1..6 (default 3)
 *              1: _period    - Number - seconds for one full sweep, lower = harder (default 1.4)
 *              2: _zoneWidth - Number - sweet-spot width as a track fraction 0.05..0.4 (default 0.16)
 *              3: _timeLimit - Number - seconds on the clock, 0 = none (default 0)
 *              4: _title     - String - dialog heading (default "LOCKPICK")
 * _resolve - Code  - called exactly once with [_success] (Boolean) when the challenge ends
 *
 * Return Value:
 * Nothing (result delivered asynchronously through _resolve)
 *
 * Example:
 * [[3, 1.4, 0.16, 0, "PADLOCK"], { params ["_ok"]; systemChat str _ok; }] call Waldo_fnc_MiniGameLockpick;
 */

disableSerialization;

params [
    ["_config", []],
    ["_resolve", {}]
];

if (!hasInterface) exitWith { [false] call _resolve; };

_config params [
    ["_pins", 3],
    ["_period", 1.4],
    ["_zoneWidth", 0.16],
    ["_timeLimit", 0],
    ["_title", "LOCK CYLINDER"]
];

_pins = round _pins;
if (_pins < 1) then { _pins = 1; };
if (_pins > 6) then { _pins = 6; };
if (_period < 0.4) then { _period = 0.4; };
if (_zoneWidth < 0.05) then { _zoneWidth = 0.05; };
if (_zoneWidth > 0.4) then { _zoneWidth = 0.4; };

if (!isNull (missionNamespace getVariable ["Waldo_MG_LP_ActiveDisplay", displayNull])) exitWith {
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
private _cTrack = [0.02, 0.03, 0.04, 1];
private _cZone = [0.22, 0.62, 0.30, 1];

private _parent = findDisplay 46;
if (isNull _parent) exitWith { [false] call _resolve; };
private _display = _parent createDisplay "RscDisplayEmpty";
if (isNull _display) exitWith { [false] call _resolve; };

missionNamespace setVariable ["Waldo_MG_LP_ActiveDisplay", _display];
missionNamespace setVariable ["Waldo_MG_ActiveChallengeDisplay", _display];
[_display, "Mouse or Space: apply tension and set the current pin", _title, format ["Set all %1 lock pins while the moving pick is inside the labelled SET WINDOW.", _pins], "The set window moves and the pick accelerates after every successful pin."] call Waldo_fnc_MiniGameChallengeUILegacy;

_display setVariable ["Waldo_MG_LP_Resolve", _resolve];
_display setVariable ["Waldo_MG_LP_Done", false];
_display setVariable ["Waldo_MG_LP_PinsLeft", _pins];
_display setVariable ["Waldo_MG_LP_PinsTotal", _pins];
_display setVariable ["Waldo_MG_LP_Period", _period];
_display setVariable ["Waldo_MG_LP_ZoneWidth", _zoneWidth];
_display setVariable ["Waldo_MG_LP_T0", time];

_display setVariable ["Waldo_MG_LP_Finish", {
    params ["_disp", "_ok", ["_resultKey", ""]];
    if (isNull _disp) exitWith {};
    if (_disp getVariable ["Waldo_MG_LP_Done", false]) exitWith {};
    _disp setVariable ["Waldo_MG_LP_Done", true];
    [_disp, _ok, _resultKey] call (_disp getVariable ["Waldo_IMG_ShowResult", {}]);
    private _fnResolve = _disp getVariable ["Waldo_MG_LP_Resolve", {}];
    missionNamespace setVariable ["Waldo_MG_LP_ActiveDisplay", displayNull];
    [{
        params ["_disp", "_res", "_ok"];
        if (!isNull _disp) then { _disp closeDisplay 1; };
        [_ok] call _res;
    }, [_disp, _fnResolve, _ok], if (_disp getVariable ["Waldo_IMG_ReducedMotion", false]) then {0.12} else {if (_ok) then {0.45} else {0.5}}] call CBA_fnc_waitAndExecute;
}];

// Current marker fraction 0..1 from a triangle (ping-pong) wave.
_display setVariable ["Waldo_MG_LP_Fraction", {
    params ["_disp"];
    private _t0 = _disp getVariable ["Waldo_MG_LP_T0", time];
    private _p = _disp getVariable ["Waldo_MG_LP_Period", 1.4];
    private _phase = ((time - _t0) / _p) mod 1;
    if (_phase < 0.5) then { 2 * _phase } else { 2 * (1 - _phase) }
}];

// Layout.
private _w = 0.42 * safezoneW;
private _h = 0.39 * safezoneH;
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
_status ctrlSetPosition [_x, _y + 0.055 * safezoneH, _w, 0.035 * safezoneH];
_status ctrlSetTextColor _cText;
_status ctrlSetText format ["Set the pins: %1 remaining", _pins];
_status ctrlCommit 0;
_display setVariable ["Waldo_MG_LP_StatusCtrl", _status];

// Lock-cylinder cross-section: each pin changes from raised steel to green when set.
private _pinCtrls = [];
private _pinW = (_w - 0.06 * safezoneW) / _pins;
for "_i" from 0 to (_pins - 1) do {
    private _pin = _display ctrlCreate ["RscText", -1];
    _pin ctrlSetPosition [_x + 0.03 * safezoneW + _i * _pinW, _y + 0.105 * safezoneH, _pinW - 0.008 * safezoneW, 0.075 * safezoneH];
    _pin ctrlSetText format ["PIN %1  [UNSET]", _i + 1];
    _pin ctrlSetBackgroundColor [0.24, 0.28, 0.34, 1];
    _pin ctrlSetTextColor [0.88, 0.90, 0.94, 1];
    _pin ctrlCommit 0;
    _pinCtrls pushBack _pin;
};
_display setVariable ["Waldo_MG_LP_PinCtrls", _pinCtrls];

// Track geometry.
private _trackX = _x + 0.02 * safezoneW;
private _trackW = _w - 0.04 * safezoneW;
private _trackY = _y + 0.215 * safezoneH;
private _trackH = 0.05 * safezoneH;
_display setVariable ["Waldo_MG_LP_TrackX", _trackX];
_display setVariable ["Waldo_MG_LP_TrackW", _trackW];

private _track = _display ctrlCreate ["RscText", -1];
_track ctrlSetPosition [_trackX, _trackY, _trackW, _trackH];
_track ctrlSetBackgroundColor _cTrack;
_track ctrlCommit 0;

private _zone = _display ctrlCreate ["RscText", -1];
_zone ctrlSetBackgroundColor _cZone;
_zone ctrlSetText "SET WINDOW";
_zone ctrlSetTextColor [0.02, 0.08, 0.03, 1];
_zone ctrlSetFontHeight (0.012 * safezoneH);
_zone ctrlCommit 0;
_display setVariable ["Waldo_MG_LP_ZoneCtrl", _zone];
_display setVariable ["Waldo_MG_LP_TrackY", _trackY];
_display setVariable ["Waldo_MG_LP_TrackH", _trackH];

private _marker = _display ctrlCreate ["RscText", -1];
_marker ctrlSetBackgroundColor _cAccentLt;
_marker ctrlCommit 0;
_display setVariable ["Waldo_MG_LP_MarkerCtrl", _marker];

// Places a fresh random sweet spot.
_display setVariable ["Waldo_MG_LP_NewZone", {
    params ["_disp"];
    private _zw = _disp getVariable ["Waldo_MG_LP_ZoneWidth", 0.16];
    private _start = random (1 - _zw);
    _disp setVariable ["Waldo_MG_LP_ZoneStart", _start];
    private _tx = _disp getVariable ["Waldo_MG_LP_TrackX", 0];
    private _tw = _disp getVariable ["Waldo_MG_LP_TrackW", 0];
    private _ty = _disp getVariable ["Waldo_MG_LP_TrackY", 0];
    private _th = _disp getVariable ["Waldo_MG_LP_TrackH", 0];
    private _zc = _disp getVariable ["Waldo_MG_LP_ZoneCtrl", controlNull];
    if (!isNull _zc) then {
        _zc ctrlSetPosition [_tx + _start * _tw, _ty, _zw * _tw, _th];
        _zc ctrlCommit 0;
    };
}];
[_display] call (_display getVariable "Waldo_MG_LP_NewZone");

// Attempt to set the current pin.
_display setVariable ["Waldo_MG_LP_Try", {
    params ["_disp"];
    if (_disp getVariable ["Waldo_MG_LP_Done", false]) exitWith {};
    private _f = [_disp] call (_disp getVariable "Waldo_MG_LP_Fraction");
    private _zs = _disp getVariable ["Waldo_MG_LP_ZoneStart", 0];
    private _zw = _disp getVariable ["Waldo_MG_LP_ZoneWidth", 0.16];
    if (_f >= _zs && {_f <= (_zs + _zw)}) then {
        private _left = (_disp getVariable ["Waldo_MG_LP_PinsLeft", 1]) - 1;
        _disp setVariable ["Waldo_MG_LP_PinsLeft", _left];
        private _total = _disp getVariable ["Waldo_MG_LP_PinsTotal", 1];
        private _pinCtrls = _disp getVariable ["Waldo_MG_LP_PinCtrls", []];
        private _setIndex = _total - _left - 1;
        if (_setIndex >= 0 && {_setIndex < count _pinCtrls}) then {
            (_pinCtrls select _setIndex) ctrlSetText format ["PIN %1  [SET]", _setIndex + 1];
            (_pinCtrls select _setIndex) ctrlSetBackgroundColor [0.10, 0.34, 0.16, 1];
            (_pinCtrls select _setIndex) ctrlSetTextColor [0.55, 1, 0.65, 1];
        };
        if (_left <= 0) exitWith {
            private _fin = _disp getVariable ["Waldo_MG_LP_Finish", {}];
            [_disp, true] call _fin;
        };
        // Next pin: tighten the timing a little and move the sweet spot.
        private _p = _disp getVariable ["Waldo_MG_LP_Period", 1.4];
        _disp setVariable ["Waldo_MG_LP_Period", (_p * 0.85) max 0.4];
        _disp setVariable ["Waldo_MG_LP_T0", time];
        [_disp] call (_disp getVariable "Waldo_MG_LP_NewZone");
        private _statusCtrl = _disp getVariable ["Waldo_MG_LP_StatusCtrl", controlNull];
        if (!isNull _statusCtrl) then {
            _statusCtrl ctrlSetText format ["Set the pins: %1 remaining", _left];
        };
    } else {
        private _fin = _disp getVariable ["Waldo_MG_LP_Finish", {}];
        [_disp, false] call _fin;
    };
}];

// SET PIN button.
private _setBtn = _display ctrlCreate ["RscButton", -1];
_setBtn ctrlSetPosition [_trackX, _y + 0.30 * safezoneH, _trackW, 0.055 * safezoneH];
_setBtn ctrlSetText "APPLY TENSION / SET PIN  (Space)";
_setBtn ctrlSetBackgroundColor _cAccent;
_setBtn ctrlSetTextColor [0.03, 0.04, 0.06, 1];
_setBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = ctrlParent _ctrl;
    if (isNull _disp) exitWith {};
    [_disp] call (_disp getVariable "Waldo_MG_LP_Try");
}];
_setBtn ctrlCommit 0;

// Keys: Space attempts, Escape aborts.
_display displayAddEventHandler ["KeyDown", {
    params ["_disp", "_key"];
    if !(_disp getVariable ["Waldo_IMG_Started", false]) exitWith {_key != 1};
    if (_key == 1) exitWith {
        private _fin = _disp getVariable ["Waldo_MG_LP_Finish", {}];
        [_disp, _fin] call (_disp getVariable ["Waldo_IMG_RequestAbort", {}]);
        true
    };
    if (_key == 57) exitWith {
        [_disp] call (_disp getVariable "Waldo_MG_LP_Try");
        true
    };
    false
}];

// Animation + optional countdown loop.
[_display, _timeLimit] spawn {
    params ["_disp", "_timeLimit"];
    waitUntil {isNull _disp || {_disp getVariable ["Waldo_IMG_Started", false]}};
    if (isNull _disp) exitWith {};
    private _deadline = if (_timeLimit > 0) then { time + _timeLimit } else { -1 };
    private _mHalf = 0.004 * safezoneW;
    while { !isNull _disp && {!(_disp getVariable ["Waldo_MG_LP_Done", false])} } do {
        if (_deadline > 0 && {(_deadline - time) <= 0}) exitWith {
            private _fin = _disp getVariable ["Waldo_MG_LP_Finish", {}];
            [_disp, false, "timeoutText"] call _fin;
        };
        private _f = [_disp] call (_disp getVariable "Waldo_MG_LP_Fraction");
        private _tx = _disp getVariable ["Waldo_MG_LP_TrackX", 0];
        private _tw = _disp getVariable ["Waldo_MG_LP_TrackW", 0];
        private _ty = _disp getVariable ["Waldo_MG_LP_TrackY", 0];
        private _th = _disp getVariable ["Waldo_MG_LP_TrackH", 0];
        private _mk = _disp getVariable ["Waldo_MG_LP_MarkerCtrl", controlNull];
        if (!isNull _mk) then {
            _mk ctrlSetPosition [_tx + _f * _tw - _mHalf, _ty, 2 * _mHalf, _th];
            _mk ctrlCommit 0;
        };
        sleep 0.02;
    };
};
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

/*
 * Hydraulic/pneumatic manifold balancing procedure.
 * Config: [valveCount(2..4), difficulty(1..3), settleTime, timeLimit, title]
 */
disableSerialization;
params [["_config", []], ["_resolve", {}]];
_config params [["_valveCount", 3], ["_difficulty", 1], ["_settleTime", 2], ["_timeLimit", 45], ["_title", "HYDRAULIC MANIFOLD"]];
_valveCount = ((round _valveCount) max 2) min 4;
_difficulty = ((round _difficulty) max 1) min 3;
_settleTime = _settleTime max 0.5;
private _band = [0.11, 0.08, 0.055] select (_difficulty - 1);

private _display = [
    _title,
    "Balance every pressure line inside its engraved SAFE band and hold the manifold stable.",
    _timeLimit,
    _resolve,
    0.48,
    "Mouse: valve -/+ or wheel; keyboard alternatives shown on each line",
    "Valves are mechanically coupled. LOW/HIGH captions and needle position remain authoritative."
] call Waldo_fnc_MiniGameChallengeUI;
if (isNull _display) exitWith {};

private _values = [];
private _targets = [];
for "_index" from 0 to (_valveCount - 1) do {
    _values pushBack (0.12 + random 0.76);
    _targets pushBack (0.28 + random 0.44);
};
private _allInitiallySafe = true;
for "_index" from 0 to (_valveCount - 1) do {
    if (abs ((_values select _index) - (_targets select _index)) > _band) exitWith {_allInitiallySafe = false;};
};
if (_allInitiallySafe) then {
    _values set [0, (((_targets select 0) + _band + 0.22) max 0) min 1];
};
_display setVariable ["Waldo_MG_PR_Values", _values];
_display setVariable ["Waldo_MG_PR_Targets", _targets];
_display setVariable ["Waldo_MG_PR_Band", _band];
_display setVariable ["Waldo_MG_PR_Settle", _settleTime];
_display setVariable ["Waldo_MG_PR_StableStart", -1];
_display setVariable ["Waldo_MG_PR_Selected", 0];

private _manifold = [_display, "RscText", [1.5, 3, 37, 20], "hydraulic manifold casing"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_manifold ctrlSetBackgroundColor [0.10, 0.13, 0.13, 1];
private _header = [_display, "RscText", [2.5, 3.8, 35, 1.5], "manifold warning plate"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_header ctrlSetText format ["HPM-%1 // COUPLED PRESSURE LINES // HOLD %2s", _valveCount, _settleTime];
_header ctrlSetTextColor [0.94, 0.78, 0.30, 1];
_header ctrlSetBackgroundColor [0.04, 0.05, 0.045, 1];

private _columnWidth = 34 / _valveCount;
private _gaugeCentres = [];
private _labels = [];
private _valveButtons = [];
private _needleSegments = [];
private _valveMarkers = [];
for "_index" from 0 to (_valveCount - 1) do {
    private _columnX = 3 + (_index * _columnWidth);
    private _centreX = _columnX + (_columnWidth / 2);
    private _centreY = 10;
    _gaugeCentres pushBack [_centreX, _centreY];
    private _bay = [_display, "RscText", [_columnX + 0.3, 5.8, _columnWidth - 0.6, 16], format ["pressure line %1 instrument bay", _index + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _bay ctrlSetBackgroundColor [0.045, 0.055, 0.055, 1];
    private _gaugeFace = [_display, "RscText", [_centreX - 3.1, 6.4, 6.2, 7.2], format ["pressure gauge %1 face", _index + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _gaugeFace ctrlSetBackgroundColor [0.015, 0.025, 0.022, 1];
    for "_tick" from 0 to 12 do {
        private _fraction = _tick / 12;
        private _angle = -130 + (260 * _fraction);
        private _target = _targets select _index;
        private _safe = abs (_fraction - _target) <= _band;
        private _tickControl = [_display, "RscText", [
            _centreX + (2.45 * sin _angle) - 0.18,
            _centreY - (2.8 * cos _angle) - 0.18,
            0.36,
            0.36
        ], format ["gauge %1 %2 tick", _index + 1, if (_safe) then {"SAFE"} else {"scale"}]] call Waldo_fnc_MiniGameEquipmentCreateControl;
        _tickControl ctrlSetBackgroundColor (if (_safe) then {[0.28, 0.72, 0.42, 1]} else {[0.62, 0.62, 0.54, 1]});
    };
    private _label = [_display, "RscText", [_columnX + 0.7, 13.8, _columnWidth - 1.4, 1.7], format ["pressure line %1 state label", _index + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _label ctrlSetText format ["LINE %1 [CHECK]", _index + 1];
    _label ctrlSetBackgroundColor [0.02, 0.035, 0.03, 1];
    _label ctrlSetFontHeight 0.030;
    _labels pushBack _label;
    private _pipe = [_display, "RscText", [_centreX - 0.28, 15.5, 0.56, 2.1], format ["pressure line %1 pipe", _index + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _pipe ctrlSetBackgroundColor [0.34, 0.37, 0.36, 1];
    private _valve = [_display, "RscButton", [_centreX - 2.2, 17.1, 4.4, 3.2], format ["pressure line %1 valve wheel", _index + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _valve ctrlSetText format ["VALVE %1 WHEEL", _index + 1];
    _valve ctrlSetBackgroundColor [0.16, 0.19, 0.18, 1];
    _valve ctrlSetTooltip "Mouse wheel adjusts this valve; neighbouring lines are coupled";
    _valve setVariable ["Waldo_MG_PR_Index", _index];
    _valve ctrlAddEventHandler ["MouseZChanged", {
        params ["_control", "_change"];
        private _display = ctrlParent _control;
        [_display, _control getVariable ["Waldo_MG_PR_Index", 0]] call (_display getVariable ["Waldo_MG_PR_Select", {}]);
        [_display, _control getVariable ["Waldo_MG_PR_Index", 0], 0.02 * _change] call (_display getVariable ["Waldo_MG_PR_Adjust", {}]);
        true
    }];
    _valve ctrlAddEventHandler ["ButtonClick", {
        params ["_control"];
        private _display = ctrlParent _control;
        [_display, _control getVariable ["Waldo_MG_PR_Index", 0]] call (_display getVariable ["Waldo_MG_PR_Select", {}]);
    }];
    _valveButtons pushBack _valve;
    private _minus = [_display, "RscButton", [_columnX + 0.7, 20.5, (_columnWidth / 2) - 0.9, 1.2], format ["close pressure valve %1", _index + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _minus ctrlSetText "CLOSE -";
    _minus setVariable ["Waldo_MG_PR_Index", _index];
    _minus setVariable ["Waldo_MG_PR_Delta", -0.025];
    private _plus = [_display, "RscButton", [_centreX + 0.2, 20.5, (_columnWidth / 2) - 0.9, 1.2], format ["open pressure valve %1", _index + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _plus ctrlSetText "OPEN +";
    _plus setVariable ["Waldo_MG_PR_Index", _index];
    _plus setVariable ["Waldo_MG_PR_Delta", 0.025];
    {
        _x ctrlAddEventHandler ["ButtonClick", {
            params ["_control"];
            private _display = ctrlParent _control;
            [_display, _control getVariable ["Waldo_MG_PR_Index", 0]] call (_display getVariable ["Waldo_MG_PR_Select", {}]);
            [_display, _control getVariable ["Waldo_MG_PR_Index", 0], _control getVariable ["Waldo_MG_PR_Delta", 0]] call (_display getVariable ["Waldo_MG_PR_Adjust", {}]);
        }];
    } forEach [_minus, _plus];
    _needleSegments pushBack [];
    _valveMarkers pushBack [];
};
_display setVariable ["Waldo_MG_PR_GaugeCentres", _gaugeCentres];
_display setVariable ["Waldo_MG_PR_Labels", _labels];
_display setVariable ["Waldo_MG_PR_Valves", _valveButtons];
_display setVariable ["Waldo_MG_PR_NeedleSegments", _needleSegments];
_display setVariable ["Waldo_MG_PR_ValveMarkers", _valveMarkers];

// Common lower bus and labelled flow direction.
[_display, [[3, 22.2], [37, 22.2]], [0.36, 0.42, 0.42, 1], 0.36, "manifold common pressure bus"] call Waldo_fnc_MiniGameEquipmentPolyline;
private _flow = [_display, "RscText", [13, 21.9, 14, 1.3], "manifold flow direction"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_flow ctrlSetText "FLOW >>> COMMON RETURN";
_flow ctrlSetTextColor [0.70, 0.84, 0.86, 1];

_display setVariable ["Waldo_MG_PR_Select", {
    params ["_display", "_index"];
    private _valves = _display getVariable ["Waldo_MG_PR_Valves", []];
    if (_index < 0 || {_index >= count _valves}) exitWith {};
    _display setVariable ["Waldo_MG_PR_Selected", _index];
    {
        _x ctrlSetBackgroundColor (if (_forEachIndex == _index) then {[0.34, 0.29, 0.12, 1]} else {[0.16, 0.19, 0.18, 1]});
    } forEach _valves;
    private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then {_status ctrlSetText format ["[SELECTED] VALVE %1 // LEFT/RIGHT OR OPEN/CLOSE", _index + 1];};
}];

_display setVariable ["Waldo_MG_PR_Refresh", {
    params ["_display"];
    private _values = _display getVariable ["Waldo_MG_PR_Values", []];
    private _targets = _display getVariable ["Waldo_MG_PR_Targets", []];
    private _band = _display getVariable ["Waldo_MG_PR_Band", 0.1];
    private _centres = _display getVariable ["Waldo_MG_PR_GaugeCentres", []];
    private _labels = _display getVariable ["Waldo_MG_PR_Labels", []];
    private _needles = _display getVariable ["Waldo_MG_PR_NeedleSegments", []];
    private _markers = _display getVariable ["Waldo_MG_PR_ValveMarkers", []];
    private _allSafe = true;
    for "_index" from 0 to ((count _values) - 1) do {
        {if (!isNull _x) then {ctrlDelete _x;};} forEach (_needles select _index);
        {if (!isNull _x) then {ctrlDelete _x;};} forEach (_markers select _index);
        private _centre = _centres select _index;
        private _value = _values select _index;
        private _angle = -130 + (260 * _value);
        private _needle = [_display, [
            [_centre select 0, _centre select 1],
            [(_centre select 0) + (2.05 * sin _angle), (_centre select 1) - (2.35 * cos _angle)]
        ], [0.96, 0.75, 0.28, 1], 0.20, format ["pressure gauge %1 needle", _index + 1]] call Waldo_fnc_MiniGameEquipmentPolyline;
        _needles set [_index, _needle];
        private _valveAngle = -120 + (240 * _value);
        // The mechanical handle sits above the labelled hit target. Drawing it
        // through RscButton text made both the symbol and wording illegible.
        private _valveY = 16.65;
        private _marker = [_display, [
            [_centre select 0, _valveY],
            [(_centre select 0) + (0.72 * sin _valveAngle), _valveY - (0.62 * cos _valveAngle)]
        ], [0.78, 0.86, 0.84, 1], 0.22, format ["pressure valve %1 handle", _index + 1]] call Waldo_fnc_MiniGameEquipmentPolyline;
        _markers set [_index, _marker];
        private _safe = abs (_value - (_targets select _index)) <= _band;
        private _direction = if (_safe) then {"[SAFE] HOLD"} else {if (_value < ((_targets select _index) - _band)) then {"[LOW ^] OPEN"} else {"[HIGH v] CLOSE"}};
        private _label = _labels select _index;
        _label ctrlSetText format ["LINE %1 %2", _index + 1, _direction];
        _label ctrlSetTextColor (if (_safe) then {[0.55, 1, 0.65, 1]} else {[0.96, 0.78, 0.30, 1]});
        if (!_safe) then {_allSafe = false;};
    };
    _display setVariable ["Waldo_MG_PR_NeedleSegments", _needles];
    _display setVariable ["Waldo_MG_PR_ValveMarkers", _markers];
    if (_allSafe) then {
        if ((_display getVariable ["Waldo_MG_PR_StableStart", -1]) < 0) then {_display setVariable ["Waldo_MG_PR_StableStart", time];};
    } else {
        _display setVariable ["Waldo_MG_PR_StableStart", -1];
    };
    private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then {_status ctrlSetText (if (_allSafe) then {"[SAFE] ALL LINES // HOLD MANIFOLD STEADY"} else {"[ADJUST] FOLLOW EACH LOW/HIGH CAPTION"});};
}];
_display setVariable ["Waldo_MG_PR_Adjust", {
    params ["_display", "_index", "_delta"];
    if (!(_display getVariable ["Waldo_IMG_Started", false]) || {_display getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
    private _values = _display getVariable ["Waldo_MG_PR_Values", []];
    for "_other" from 0 to ((count _values) - 1) do {
        private _coupling = if (_other == _index) then {1} else {if (abs (_other - _index) == 1) then {-0.18} else {0}};
        _values set [_other, (((_values select _other) + (_delta * _coupling)) max 0) min 1];
    };
    _display setVariable ["Waldo_MG_PR_Values", _values];
    _display setVariable ["Waldo_MG_PR_StableStart", -1];
    [_display] call (_display getVariable ["Waldo_MG_PR_Refresh", {}]);
}];
[_display, "KeyDown", {
    params ["_display", "_key"];
    private _count = count (_display getVariable ["Waldo_MG_PR_Values", []]);
    if (_key >= 2 && {_key < 2 + _count}) exitWith {
        [_display, _key - 2] call (_display getVariable ["Waldo_MG_PR_Select", {}]);
        true
    };
    if (_key in [203, 205]) exitWith {
        private _selected = _display getVariable ["Waldo_MG_PR_Selected", 0];
        [_display, _selected, if (_key == 203) then {-0.025} else {0.025}] call (_display getVariable ["Waldo_MG_PR_Adjust", {}]);
        true
    };
    false
}] call Waldo_fnc_MiniGameEquipmentAddDisplayHandler;
[_display, 0] call (_display getVariable ["Waldo_MG_PR_Select", {}]);
[_display] call (_display getVariable ["Waldo_MG_PR_Refresh", {}]);

private _settleWorker = [_display] spawn {
    params ["_display"];
    waitUntil {isNull _display || {_display getVariable ["Waldo_IMG_Started", false]}};
    while {!isNull _display && {!(_display getVariable ["Waldo_MG_UI_Done", false])}} do {
        private _stable = _display getVariable ["Waldo_MG_PR_StableStart", -1];
        if (_stable >= 0 && {(time - _stable) >= (_display getVariable ["Waldo_MG_PR_Settle", 2])}) exitWith {
            [_display, true, "[OK] MANIFOLD PRESSURE STABLE"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
        };
        uiSleep 0.05;
    };
};
private _workers = _display getVariable ["Waldo_MG_UI_Workers", []];
_workers pushBack _settleWorker;
_display setVariable ["Waldo_MG_UI_Workers", _workers];
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

/*
 * Cutaway lock-cylinder binding procedure.
 * Config: [pins(1..6), sweepPeriod, sweetSpotWidth(0.05..0.4), timeLimit, title]
 */
disableSerialization;
params [["_config", []], ["_resolve", {}]];
_config params [["_pins", 3], ["_period", 2.8], ["_zoneWidth", 0.16], ["_timeLimit", 0], ["_title", "LOCK CYLINDER"]];
_pins = ((round _pins) max 1) min 6;
_period = _period max 0.8;
_zoneWidth = (_zoneWidth max 0.05) min 0.4;

private _display = [
    _title,
    "Apply enough wrench pressure to bind the active pin, then set it as the pick reaches the marked band.",
    _timeLimit,
    _resolve,
    0.49,
    "LESS/MORE adjusts binding pressure; SET PIN or Space confirms; Left/Right also adjusts",
    "Step 1: reach [BIND]. Step 2: press SET PIN while the yellow pick-height marker is inside the [SET] band."
] call Waldo_fnc_MiniGameChallengeUI;
if (isNull _display) exitWith {};

_display setVariable ["Waldo_MG_LP_Pins", _pins];
_display setVariable ["Waldo_MG_LP_CurrentPin", 0];
_display setVariable ["Waldo_MG_LP_Period", _period];
_display setVariable ["Waldo_MG_LP_ZoneWidth", _zoneWidth];
_display setVariable ["Waldo_MG_LP_ZoneStart", 0.15 + random (0.7 - _zoneWidth)];
_display setVariable ["Waldo_MG_LP_Sweep", 0];
_display setVariable ["Waldo_MG_LP_StartedAt", -1];
_display setVariable ["Waldo_MG_LP_Tension", 0.5];
_display setVariable ["Waldo_MG_LP_TensionTarget", 0.25 + random 0.5];
_display setVariable ["Waldo_MG_LP_TensionTolerance", 0.10];

private _bench = [_display, "RscText", [1.5, 3, 37, 20], "locksmith inspection bench"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_bench ctrlSetBackgroundColor [0.095, 0.10, 0.09, 1];
private _procedure = [_display, "RscText", [2.3, 3.45, 35.4, 1.15], "lockpick operating steps"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_procedure ctrlSetText "1 ADJUST PRESSURE UNTIL [BIND]  >  2 WAIT FOR MARKER IN [SET]  >  3 SET ACTIVE PIN";
_procedure ctrlSetTextColor [0.96, 0.78, 0.30, 1];
_procedure ctrlSetBackgroundColor [0.025, 0.035, 0.03, 1];
_procedure ctrlSetFontHeight 0.026;
private _cylinderOuter = [_display, "RscText", [3, 5, 28, 13], "cutaway lock cylinder housing"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_cylinderOuter ctrlSetBackgroundColor [0.25, 0.27, 0.25, 1];
private _cylinderInner = [_display, "RscText", [4, 6, 26, 11], "lock cylinder plug cutaway"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_cylinderInner ctrlSetBackgroundColor [0.075, 0.08, 0.075, 1];
private _shearLine = [_display, "RscText", [4.5, 10.25, 25, 0.35], "lock cylinder shear line"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_shearLine ctrlSetBackgroundColor [0.94, 0.72, 0.25, 1];
private _shearLabel = [_display, "RscText", [24.5, 8.8, 5, 1.3], "shear line label"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_shearLabel ctrlSetText "SHEAR LINE";
_shearLabel ctrlSetTextColor [0.96, 0.78, 0.30, 1];

private _pinSpacing = 19 / _pins;
private _driverPins = [];
private _keyPins = [];
private _pinLabels = [];
for "_index" from 0 to (_pins - 1) do {
    private _pinX = 6 + (_index * _pinSpacing);
    private _chamber = [_display, "RscText", [_pinX - 0.5, 6.4, 2.1, 9.5], format ["pin %1 chamber", _index + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _chamber ctrlSetBackgroundColor [0.035, 0.04, 0.035, 1];
    private _spring = [_display, "RscText", [_pinX, 6.75, 1.1, 1.2], format ["pin %1 spring", _index + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _spring ctrlSetText "||||";
    _spring ctrlSetTextColor [0.68, 0.70, 0.64, 1];
    private _driver = [_display, "RscText", [_pinX, 8, 1.1, 2.1], format ["pin %1 driver pin", _index + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _driver ctrlSetBackgroundColor [0.52, 0.54, 0.49, 1];
    _driverPins pushBack _driver;
    private _keyPin = [_display, "RscText", [_pinX, 10.7, 1.1, 3.8], format ["pin %1 key pin", _index + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _keyPin ctrlSetBackgroundColor [0.70, 0.58, 0.28, 1];
    _keyPins pushBack _keyPin;
    // Pin state belongs above its chamber. Keeping it away from the pick shaft
    // and tension-wrench caption prevents the three labels reading as one line.
    private _label = [_display, "RscText", [_pinX - 0.95, 5.15, 3, 0.9], format ["pin %1 progress label", _index + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _label ctrlSetText format ["P%1 [OPEN]", _index + 1];
    _label ctrlSetTextColor [0.88, 0.87, 0.78, 1];
    _pinLabels pushBack _label;
};
_display setVariable ["Waldo_MG_LP_DriverPins", _driverPins];
_display setVariable ["Waldo_MG_LP_KeyPins", _keyPins];
_display setVariable ["Waldo_MG_LP_PinLabels", _pinLabels];

private _pickShaft = [_display, "RscText", [5.5, 15.2, 20, 0.35], "lock pick shaft"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_pickShaft ctrlSetBackgroundColor [0.72, 0.78, 0.76, 1];
private _pickTip = [_display, "RscText", [6, 13.9, 0.45, 1.5], "moving lock pick tip"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_pickTip ctrlSetBackgroundColor [0.82, 0.86, 0.84, 1];
_display setVariable ["Waldo_MG_LP_PickTip", _pickTip];
private _tension = [_display, "RscText", [4.5, 16, 8, 0.5], "tension wrench"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_tension ctrlSetBackgroundColor [0.48, 0.52, 0.50, 1];
_display setVariable ["Waldo_MG_LP_TensionTool", _tension];
private _tensionLabel = [_display, "RscText", [13, 15.7, 9, 1.15], "tension wrench label"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_tensionLabel ctrlSetText "PRESSURE BINDS PIN >";
_tensionLabel ctrlSetTextColor [0.72, 0.76, 0.70, 1];

private _meterFrame = [_display, "RscText", [3, 19, 28, 3], "binding feedback meter"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_meterFrame ctrlSetBackgroundColor [0.025, 0.035, 0.03, 1];
private _meterCaption = [_display, "RscText", [3.5, 18.05, 27, 0.9], "pick height timing instruction"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_meterCaption ctrlSetText "PICK HEIGHT // PRESS SET WHEN YELLOW MARKER ENTERS THE [SET] BAND";
_meterCaption ctrlSetTextColor [0.82, 0.86, 0.78, 1];
_meterCaption ctrlSetFontHeight 0.024;
private _meterTrack = [_display, "RscText", [4, 20.05, 26, 0.8], "binding meter track"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_meterTrack ctrlSetBackgroundColor [0.18, 0.20, 0.18, 1];
private _zone = [_display, "RscText", [4, 19.75, 3, 1.4], "binding alignment zone"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_zone ctrlSetBackgroundColor [0.22, 0.56, 0.34, 0.82];
_zone ctrlSetText "";
_display setVariable ["Waldo_MG_LP_ZoneControl", _zone];
private _marker = [_display, "RscText", [4, 19.55, 0.45, 1.8], "binding feedback marker"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_marker ctrlSetBackgroundColor [0.96, 0.78, 0.30, 1];
_display setVariable ["Waldo_MG_LP_Marker", _marker];
private _tensionReadout = [_display, "RscText", [31.8, 4.2, 6, 2.1], "lock tension readout"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_tensionReadout ctrlSetText "PRESSURE 50% [CHECK]";
_tensionReadout ctrlSetBackgroundColor [0.025, 0.035, 0.03, 1];
_tensionReadout ctrlSetTextColor [0.96, 0.78, 0.30, 1];
[_tensionReadout, 0.032, 0.016] call Waldo_fnc_MiniGameEquipmentFitText;
_display setVariable ["Waldo_MG_LP_TensionReadout", _tensionReadout];
private _tensionMinus = [_display, "RscButton", [32.0, 6.8, 2.6, 2.2], "reduce lock tension"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_tensionMinus ctrlSetText "LESS";
_tensionMinus setVariable ["Waldo_MG_LP_TensionDelta", -0.05];
private _tensionPlus = [_display, "RscButton", [35.0, 6.8, 2.6, 2.2], "increase lock tension"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_tensionPlus ctrlSetText "MORE";
_tensionPlus setVariable ["Waldo_MG_LP_TensionDelta", 0.05];
private _setButton = [_display, "RscButton", [32.2, 10, 5.3, 6], "set active lock pin"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_setButton ctrlSetText "SET PIN IN [SET]";
_setButton ctrlSetBackgroundColor [0.18, 0.20, 0.18, 1];
_setButton ctrlSetTooltip "Requires [BIND] tension and the moving marker inside [SET]. Space also works.";
[_setButton, 0.032, 0.016] call Waldo_fnc_MiniGameEquipmentFitText;

_display setVariable ["Waldo_MG_LP_UpdateTension", {
    params ["_display"];
    private _value = _display getVariable ["Waldo_MG_LP_Tension", 0.5];
    private _target = _display getVariable ["Waldo_MG_LP_TensionTarget", 0.5];
    private _tolerance = _display getVariable ["Waldo_MG_LP_TensionTolerance", 0.1];
    private _state = if (abs (_value - _target) <= _tolerance) then {"[BIND]"} else {if (_value < _target) then {"[LOW]"} else {"[HIGH]"}};
    private _readout = _display getVariable ["Waldo_MG_LP_TensionReadout", controlNull];
    if (!isNull _readout) then {
        _readout ctrlSetText format ["PRESSURE %1%% %2", round (_value * 100), _state];
        _readout ctrlSetTextColor (if (_state == "[BIND]") then {[0.55, 1, 0.65, 1]} else {[0.96, 0.78, 0.30, 1]});
        [_readout, 0.032, 0.016] call Waldo_fnc_MiniGameEquipmentFitText;
    };
    private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status && {_display getVariable ["Waldo_IMG_Started", false]}) then {
        _status ctrlSetText (if (_state == "[BIND]") then {"[STEP 2/3] PIN IS BINDING // WAIT FOR YELLOW MARKER INSIDE [SET]"} else {if (_value < _target) then {"[STEP 1/3] PRESSURE TOO LOW // SELECT MORE"} else {"[STEP 1/3] PRESSURE TOO HIGH // SELECT LESS"}});
    };
    [_display, _display getVariable ["Waldo_MG_LP_TensionTool", controlNull], [4.5, 16, 4 + (8 * _value), 0.5], 0.08] call Waldo_fnc_MiniGameEquipmentSetPosition;
}];
_display setVariable ["Waldo_MG_LP_AdjustTension", {
    params ["_display", "_delta"];
    if (!(_display getVariable ["Waldo_IMG_Started", false]) || {_display getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
    _display setVariable ["Waldo_MG_LP_Tension", (((_display getVariable ["Waldo_MG_LP_Tension", 0.5]) + _delta) max 0) min 1];
    [_display] call (_display getVariable ["Waldo_MG_LP_UpdateTension", {}]);
}];
{
    _x ctrlAddEventHandler ["ButtonClick", {
        params ["_control"];
        private _display = ctrlParent _control;
        [_display, _control getVariable ["Waldo_MG_LP_TensionDelta", 0]] call (_display getVariable ["Waldo_MG_LP_AdjustTension", {}]);
    }];
} forEach [_tensionMinus, _tensionPlus];
[_display] call (_display getVariable ["Waldo_MG_LP_UpdateTension", {}]);

_display setVariable ["Waldo_MG_LP_UpdateZone", {
    params ["_display"];
    private _start = _display getVariable ["Waldo_MG_LP_ZoneStart", 0.3];
    private _width = _display getVariable ["Waldo_MG_LP_ZoneWidth", 0.16];
    [_display, _display getVariable ["Waldo_MG_LP_ZoneControl", controlNull], [4 + (26 * _start), 19.75, 26 * _width, 1.4], 0] call Waldo_fnc_MiniGameEquipmentSetPosition;
}];
[_display] call (_display getVariable ["Waldo_MG_LP_UpdateZone", {}]);

// Single source of truth for the pick height, derived fresh from elapsed time
// rather than read back off the last rendered animation tick. SET PIN must
// judge the exact instant the player pressed it, not a value that can be up
// to one scheduler tick stale - that gap is what read as an input delay.
_display setVariable ["Waldo_MG_LP_ComputeSweep", {
    params ["_display"];
    private _startedAt = _display getVariable ["Waldo_MG_LP_StartedAt", -1];
    if (_startedAt < 0) exitWith {0};
    private _period = _display getVariable ["Waldo_MG_LP_Period", 2.8];
    private _phase = ((diag_tickTime - _startedAt) mod _period) / _period;
    if (_phase <= 0.5) then {_phase * 2} else {(1 - _phase) * 2}
}];

_display setVariable ["Waldo_MG_LP_SetPin", {
    params ["_display"];
    if (!(_display getVariable ["Waldo_IMG_Started", false]) || {_display getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
    private _sweep = [_display] call (_display getVariable ["Waldo_MG_LP_ComputeSweep", {}]);
    private _zoneStart = _display getVariable ["Waldo_MG_LP_ZoneStart", 0];
    private _zoneWidth = _display getVariable ["Waldo_MG_LP_ZoneWidth", 0.16];
    private _tension = _display getVariable ["Waldo_MG_LP_Tension", 0.5];
    private _tensionTarget = _display getVariable ["Waldo_MG_LP_TensionTarget", 0.5];
    private _tensionTolerance = _display getVariable ["Waldo_MG_LP_TensionTolerance", 0.1];
    if (abs (_tension - _tensionTarget) > _tensionTolerance) exitWith {
        private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
        if (!isNull _status) then {_status ctrlSetText (if (_tension < _tensionTarget) then {"[STEP 1/3] PRESSURE TOO LOW // SELECT MORE UNTIL [BIND]"} else {"[STEP 1/3] PRESSURE TOO HIGH // SELECT LESS UNTIL [BIND]"});};
    };
    if (_sweep < _zoneStart || {_sweep > (_zoneStart + _zoneWidth)}) exitWith {
        [_display, false, "[X] PICK SLIPPED // PIN NOT AT SHEAR LINE"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
    };
    private _index = _display getVariable ["Waldo_MG_LP_CurrentPin", 0];
    private _drivers = _display getVariable ["Waldo_MG_LP_DriverPins", []];
    private _keys = _display getVariable ["Waldo_MG_LP_KeyPins", []];
    private _labels = _display getVariable ["Waldo_MG_LP_PinLabels", []];
    [_display, _drivers select _index, [6 + (_index * (19 / (_display getVariable ["Waldo_MG_LP_Pins", 1]))), 7.95, 1.1, 2.1], 0.15] call Waldo_fnc_MiniGameEquipmentSetPosition;
    [_display, _keys select _index, [6 + (_index * (19 / (_display getVariable ["Waldo_MG_LP_Pins", 1]))), 10.55, 1.1, 3.8], 0.15] call Waldo_fnc_MiniGameEquipmentSetPosition;
    private _label = _labels select _index;
    _label ctrlSetText format ["P%1 [SET]", _index + 1];
    _label ctrlSetTextColor [0.55, 1, 0.65, 1];
    _index = _index + 1;
    _display setVariable ["Waldo_MG_LP_CurrentPin", _index];
    if (_index >= (_display getVariable ["Waldo_MG_LP_Pins", 1])) exitWith {
        [_display, true, "[OK] CYLINDER SHEAR LINE CLEARED"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
    };
    private _width = _display getVariable ["Waldo_MG_LP_ZoneWidth", 0.16];
    _display setVariable ["Waldo_MG_LP_ZoneStart", 0.10 + random (0.80 - _width)];
    _display setVariable ["Waldo_MG_LP_Tension", 0.5];
    _display setVariable ["Waldo_MG_LP_TensionTarget", 0.25 + random 0.5];
    [_display] call (_display getVariable ["Waldo_MG_LP_UpdateZone", {}]);
    [_display] call (_display getVariable ["Waldo_MG_LP_UpdateTension", {}]);
    private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then {_status ctrlSetText format ["[SET] PIN %1/%2 // BINDING PIN %3", _index, _display getVariable ["Waldo_MG_LP_Pins", 1], _index + 1];};
}];
_setButton ctrlAddEventHandler ["ButtonClick", {private _display = ctrlParent (_this select 0); [_display] call (_display getVariable ["Waldo_MG_LP_SetPin", {}]);}];
[_display, "KeyDown", {
    params ["_display", "_key"];
    if (_key == 57) exitWith {[_display] call (_display getVariable ["Waldo_MG_LP_SetPin", {}]); true};
    if (_key == 203) exitWith {[_display, -0.05] call (_display getVariable ["Waldo_MG_LP_AdjustTension", {}]); true};
    if (_key == 205) exitWith {[_display, 0.05] call (_display getVariable ["Waldo_MG_LP_AdjustTension", {}]); true};
    false
}] call Waldo_fnc_MiniGameEquipmentAddDisplayHandler;

// The pick sweep used to be driven by a spawned uiSleep loop. Scheduled scripts
// share a per-frame execution budget with every other running script in the
// mission, so under load that loop can fall meaningfully behind real elapsed
// time - the rendered marker (and, before the SetPin fix above, the SET PIN
// judgement itself) would visibly lag the moment the player actually pressed
// the key. addMissionEventHandler ["EachFrame", ...] runs unscheduled, once
// per rendered frame, independent of the scheduler queue, so the marker stays
// locked to Waldo_MG_LP_ComputeSweep's own real-time result every frame.
private _animationStarter = [_display] spawn {
    params ["_display"];
    waitUntil {isNull _display || {_display getVariable ["Waldo_IMG_Started", false]}};
    if (isNull _display) exitWith {};
    [_display] call (_display getVariable ["Waldo_MG_LP_UpdateTension", {}]);
    _display setVariable ["Waldo_MG_LP_StartedAt", diag_tickTime];
    // equipmentCleanup.sqf normally removes this handler via Waldo_MG_UI_EachFrameHandlers,
    // but that array is owned by two independently-scheduled scripts with no lock between
    // them: if Cleanup runs (and clears the array) before the pushBack below executes,
    // this id is never recorded and the shared cleanup path silently misses it. The handler
    // therefore also removes itself the first frame it observes Done, using its own id off
    // the display, so it can never outlive the challenge even when that race is lost.
    private _ehId = addMissionEventHandler ["EachFrame", {
        private _display = uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
        if (isNull _display) exitWith {};
        if (_display getVariable ["Waldo_MG_UI_Done", false]) exitWith {
            removeMissionEventHandler ["EachFrame", (_display getVariable ["Waldo_MG_LP_AnimEhId", -1])];
        };
        private _sweep = [_display] call (_display getVariable ["Waldo_MG_LP_ComputeSweep", {}]);
        // Kept in sync for the interaction-equipment QA automation harness, which polls this
        // variable directly rather than calling ComputeSweep - do not remove as "dead state".
        _display setVariable ["Waldo_MG_LP_Sweep", _sweep];
        [_display, _display getVariable ["Waldo_MG_LP_Marker", controlNull], [3.78 + (26 * _sweep), 19.55, 0.45, 1.8], 0] call Waldo_fnc_MiniGameEquipmentSetPosition;
        private _index = _display getVariable ["Waldo_MG_LP_CurrentPin", 0];
        private _keyPins = _display getVariable ["Waldo_MG_LP_KeyPins", []];
        if (_index < count _keyPins) then {
            [_display, _keyPins select _index, [6 + (_index * (19 / (_display getVariable ["Waldo_MG_LP_Pins", 1]))), 12.4 - (1.85 * _sweep), 1.1, 3.8], 0] call Waldo_fnc_MiniGameEquipmentSetPosition;
            [_display, _display getVariable ["Waldo_MG_LP_PickTip", controlNull], [6 + (_index * (19 / (_display getVariable ["Waldo_MG_LP_Pins", 1]))) + 0.3, 13.9 - (1.85 * _sweep), 0.45, 1.5], 0] call Waldo_fnc_MiniGameEquipmentSetPosition;
        };
    }];
    _display setVariable ["Waldo_MG_LP_AnimEhId", _ehId];
    private _ehHandlers = _display getVariable ["Waldo_MG_UI_EachFrameHandlers", []];
    _ehHandlers pushBack _ehId;
    _display setVariable ["Waldo_MG_UI_EachFrameHandlers", _ehHandlers];
};
private _workers = _display getVariable ["Waldo_MG_UI_Workers", []];
_workers pushBack _animationStarter;
_display setVariable ["Waldo_MG_UI_Workers", _workers];
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

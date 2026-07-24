/*
 * Secure control-console sequence procedure.
 * Config: [padCount(3..6), rounds(1..8), playbackSpeed(0.25..1.5), timeLimit, title]
 */
disableSerialization;
params [["_config", []], ["_resolve", {}]];
_config params [["_padCount", 4], ["_rounds", 4], ["_speed", 0.85], ["_timeLimit", 0], ["_title", "CONTROL CONSOLE"]];
_padCount = ((round _padCount) max 3) min 6;
_rounds = ((round _rounds) max 1) min 8;
_speed = (_speed max 0.25) min 1.5;

private _display = [
    _title,
    "Observe the system-test lamps, then reproduce the authorization sequence.",
    _timeLimit,
    _resolve,
    0.45,
    "Mouse or number keys 1-6; R or REPLAY repeats once per stage",
    "Follow the numbered/symbol caption during playback. Input is accepted only while the console reads YOUR INPUT."
] call Waldo_fnc_MiniGameChallengeUI;
if (isNull _display) exitWith {};

_display setVariable ["Waldo_MG_SQ_Sequence", [floor random _padCount]];
_display setVariable ["Waldo_MG_SQ_InputIndex", 0];
_display setVariable ["Waldo_MG_SQ_Round", 1];
_display setVariable ["Waldo_MG_SQ_Rounds", _rounds];
_display setVariable ["Waldo_MG_SQ_Speed", _speed];
_display setVariable ["Waldo_MG_SQ_PadCount", _padCount];
_display setVariable ["Waldo_MG_SQ_AcceptInput", false];
_display setVariable ["Waldo_MG_SQ_ReplayUsed", false];
_display setVariable ["Waldo_MG_SQ_PlaybackActive", false];

private _stageFrame = [_display, "RscText", [1.65, 2.65, 25.2, 2.7], "authorization stage frame"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_stageFrame ctrlSetBackgroundColor [0.22, 0.23, 0.20, 1];
private _stage = [_display, "RscText", [2, 3, 24.5, 2], "authorization stage"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_stage ctrlSetBackgroundColor [0.025, 0.055, 0.045, 1];
_stage ctrlSetText "AUTHORIZATION STAGE 1";
_stage ctrlSetTextColor [0.88, 0.92, 0.84, 1];
_stage ctrlSetFontHeight 0.036;
_display setVariable ["Waldo_MG_SQ_Stage", _stage];
private _replayFrame = [_display, "RscText", [27.15, 2.65, 11.2, 2.7], "replay control frame"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_replayFrame ctrlSetBackgroundColor [0.22, 0.23, 0.20, 1];
private _replay = [_display, "RscButton", [27.5, 3, 10.5, 2], "replay authorization sequence"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_replay ctrlSetText "REPLAY ONCE [R]";
_replay ctrlSetTooltip "Available once during each authorization stage; keyboard R";
_replay ctrlEnable false;
_display setVariable ["Waldo_MG_SQ_ReplayButton", _replay];

private _inputReadout = [_display, "RscText", [3, 8.15, 34, 1.35], "entered authorization signals"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_inputReadout ctrlSetBackgroundColor [0.025, 0.035, 0.03, 1];
_inputReadout ctrlSetText "ENTERED: --";
_inputReadout ctrlSetTextColor [0.76, 0.80, 0.74, 1];
_inputReadout ctrlSetFontHeight 0.03;
_display setVariable ["Waldo_MG_SQ_InputReadout", _inputReadout];

private _lampTrack = [_display, "RscText", [3, 6, 34, 2], "round progress lamps"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_lampTrack ctrlSetBackgroundColor [0.04, 0.045, 0.04, 1];
private _roundLamps = [];
for "_roundIndex" from 0 to (_rounds - 1) do {
    private _lampWidth = 30 / _rounds;
    private _lamp = [_display, "RscText", [5 + (_roundIndex * _lampWidth), 6.35, _lampWidth - 0.4, 1.3], format ["authorization stage %1 lamp", _roundIndex + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _lamp ctrlSetText format ["%1", _roundIndex + 1];
    _lamp ctrlSetBackgroundColor [0.09, 0.10, 0.09, 1];
    _lamp ctrlSetTextColor [0.62, 0.64, 0.58, 1];
    _roundLamps pushBack _lamp;
};
_display setVariable ["Waldo_MG_SQ_RoundLamps", _roundLamps];

private _identities = [
    ["TRIANGLE", "[1]", [0.22, 0.46, 0.72, 1]],
    ["SQUARE", "[2]", [0.74, 0.34, 0.28, 1]],
    ["DOT", "[3]", [0.28, 0.62, 0.38, 1]],
    ["DIAMOND", "[4]", [0.78, 0.64, 0.24, 1]],
    ["CROSS", "[5]", [0.56, 0.38, 0.68, 1]],
    ["HEX", "[6]", [0.24, 0.62, 0.66, 1]]
];
private _columns = if (_padCount <= 4) then {2} else {3};
private _rows = ceil (_padCount / _columns);
private _buttons = [];
private _cueOverlays = [];
for "_index" from 0 to (_padCount - 1) do {
    private _column = _index mod _columns;
    private _row = floor (_index / _columns);
    private _buttonW = if (_columns == 2) then {14} else {10};
    private _buttonH = if (_rows == 2) then {6} else {4.3};
    private _gapX = if (_columns == 2) then {3} else {1.5};
    private _startX = if (_columns == 2) then {4.5} else {3};
    private _x = _startX + (_column * (_buttonW + _gapX));
    private _y = 10 + (_row * (_buttonH + 0.7));
    private _identity = _identities select _index;
    private _guard = [_display, "RscText", [_x - 0.35, _y - 0.35, _buttonW + 0.7, _buttonH + 0.7], format ["guard for control %1", _index + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _guard ctrlSetBackgroundColor (_identity select 2);
    private _button = [_display, "RscButton", [_x, _y, _buttonW, _buttonH], format ["control %1 %2", _index + 1, _identity select 0]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _button ctrlSetText format ["%1  %2  |  READY", _identity select 1, _identity select 0];
    _button ctrlSetBackgroundColor [0.10, 0.115, 0.105, 1];
    _button ctrlSetTextColor [0.92, 0.92, 0.88, 1];
    _button ctrlSetTooltip format ["Control %1, %2 symbol. Keyboard %1.", _index + 1, _identity select 0];
    _button setVariable ["Waldo_MG_SQ_Index", _index];
    _button ctrlAddEventHandler ["ButtonClick", {
        params ["_control"];
        private _display = ctrlParent _control;
        [_display, _control getVariable ["Waldo_MG_SQ_Index", -1]] call (_display getVariable ["Waldo_MG_SQ_Activate", {}]);
    }];
    _buttons pushBack _button;
    // Playback uses a non-interactive overlay above the button. Arma's native
    // button hover rendering can therefore never obscure an observed cue.
    private _cue = [_display, "RscText", [_x, _y, _buttonW, _buttonH], format ["playback cue %1 %2", _index + 1, _identity select 0]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _cue ctrlSetText format ["%1  %2  //  [ON]", _identity select 1, _identity select 0];
    _cue ctrlSetBackgroundColor [0.96, 0.82, 0.32, 1];
    _cue ctrlSetTextColor [0.04, 0.05, 0.04, 1];
    _cue ctrlSetFontHeight 0.038;
    _cue ctrlEnable false;
    _cue ctrlShow false;
    _cueOverlays pushBack _cue;
};
_display setVariable ["Waldo_MG_SQ_Buttons", _buttons];
_display setVariable ["Waldo_MG_SQ_CueOverlays", _cueOverlays];
private _attention = [_display, "RscStructuredText", [8, 11.2, 24, 6.5], "unmissable sequence playback countdown"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_attention ctrlSetBackgroundColor [0.015, 0.022, 0.018, 0.98];
_attention ctrlSetStructuredText parseText "<t align='center' size='1.35' color='#F2C247'>EYES ON CONTROL PANEL</t><br/><t align='center' size='1.0' color='#EEE9D8'>PLAYBACK STARTING</t>";
_attention ctrlShow false;
_attention ctrlEnable false;
_display setVariable ["Waldo_MG_SQ_Attention", _attention];

_display setVariable ["Waldo_MG_SQ_ShowControl", {
    params ["_display", "_index", "_active"];
    private _buttons = _display getVariable ["Waldo_MG_SQ_Buttons", []];
    if (_index < 0 || {_index >= count _buttons}) exitWith {};
    private _button = _buttons select _index;
    private _identity = [
        ["TRIANGLE", "[1]", [0.22, 0.46, 0.72, 1]], ["SQUARE", "[2]", [0.74, 0.34, 0.28, 1]],
        ["DOT", "[3]", [0.28, 0.62, 0.38, 1]], ["DIAMOND", "[4]", [0.78, 0.64, 0.24, 1]],
        ["CROSS", "[5]", [0.56, 0.38, 0.68, 1]], ["HEX", "[6]", [0.24, 0.62, 0.66, 1]]
    ] select _index;
    private _playback = _display getVariable ["Waldo_MG_SQ_PlaybackActive", false];
    private _overlays = _display getVariable ["Waldo_MG_SQ_CueOverlays", []];
    if (_index < count _overlays) then {(_overlays select _index) ctrlShow (_playback && {_active});};
    if (_playback) exitWith {
        _button ctrlSetText format ["%1  %2  |  OBSERVE", _identity select 1, _identity select 0];
        _button ctrlSetTextColor [0.70, 0.72, 0.68, 1];
        _button ctrlSetBackgroundColor [0.07, 0.08, 0.075, 1];
    };
    _button ctrlSetText format ["%1  %2  |  %3", _identity select 1, _identity select 0, if (_active) then {"[ON] ACTIVE"} else {"READY"}];
    _button ctrlSetTextColor (if (_active) then {[0.05, 0.055, 0.05, 1]} else {[0.92, 0.92, 0.88, 1]});
    _button ctrlSetBackgroundColor (if (_active) then {[0.96, 0.82, 0.32, 1]} else {[0.10, 0.115, 0.105, 1]});
}];

_display setVariable ["Waldo_MG_SQ_Play", {
    params ["_display"];
    if (isNull _display || {_display getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
    _display setVariable ["Waldo_MG_SQ_AcceptInput", false];
    _display setVariable ["Waldo_MG_SQ_PlaybackActive", true];
    _display setVariable ["Waldo_MG_SQ_InputIndex", 0];
    _display setVariable ["Waldo_MG_SQ_Entered", []];
    { _x ctrlEnable false; } forEach (_display getVariable ["Waldo_MG_SQ_Buttons", []]);
    private _replay = _display getVariable ["Waldo_MG_SQ_ReplayButton", controlNull];
    if (!isNull _replay) then {_replay ctrlEnable false;};
    private _stage = _display getVariable ["Waldo_MG_SQ_Stage", controlNull];
    if (!isNull _stage) then {_stage ctrlSetText format ["STAGE %1 // PREPARE TO OBSERVE", _display getVariable ["Waldo_MG_SQ_Round", 1]];};
    private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then {_status ctrlSetText "[OBSERVE] SYSTEM TEST IN PROGRESS";};
    private _worker = [_display] spawn {
        params ["_display"];
        private _speed = (_display getVariable ["Waldo_MG_SQ_Speed", 0.85]) max 1.25;
        // A signal remains illuminated for at least one full second. Reduced motion
        // extends the steady cue and never shortens or removes its textual caption.
        if (_display getVariable ["Waldo_IMG_ReducedMotion", false]) then {_speed = _speed max 1.25;};
        for "_countdown" from 3 to 1 step -1 do {
            private _attention = _display getVariable ["Waldo_MG_SQ_Attention", controlNull];
            if (!isNull _attention) then {
                _attention ctrlShow true;
                _attention ctrlSetStructuredText parseText format ["<t align='center' size='1.35' color='#F2C247'>EYES ON CONTROL PANEL</t><br/><t align='center' size='1.8' color='#FFFFFF'>%1</t>", _countdown];
            };
            private _stage = _display getVariable ["Waldo_MG_SQ_Stage", controlNull];
            if (!isNull _stage) then {_stage ctrlSetText format ["EYES ON CONTROL PANEL // PLAYBACK IN %1", _countdown];};
            private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
            if (!isNull _status) then {_status ctrlSetText format ["[PREPARE] HANDS OFF CONTROLS // WATCH FOR FIRST SIGNAL // %1", _countdown];};
            uiSleep 1.0;
        };
        private _attention = _display getVariable ["Waldo_MG_SQ_Attention", controlNull];
        if (!isNull _attention) then {_attention ctrlShow false;};
        private _sequence = _display getVariable ["Waldo_MG_SQ_Sequence", []];
        private _names = ["[1] TRIANGLE", "[2] SQUARE", "[3] DOT", "[4] DIAMOND", "[5] CROSS", "[6] HEX"];
        {
            if (isNull _display || {_display getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
            private _stage = _display getVariable ["Waldo_MG_SQ_Stage", controlNull];
            if (!isNull _stage) then {_stage ctrlSetText format ["PLAYBACK %1/%2 // %3", _forEachIndex + 1, count _sequence, _names select _x];};
            private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
            if (!isNull _status) then {_status ctrlSetText format ["[OBSERVE] SIGNAL %1 OF %2 // %3", _forEachIndex + 1, count _sequence, _names select _x];};
            [_display, _x, true] call (_display getVariable ["Waldo_MG_SQ_ShowControl", {}]);
            uiSleep _speed;
            [_display, _x, false] call (_display getVariable ["Waldo_MG_SQ_ShowControl", {}]);
            uiSleep 0.45;
        } forEach _sequence;
        if (!isNull _display && {!(_display getVariable ["Waldo_MG_UI_Done", false])}) then {
            _display setVariable ["Waldo_MG_SQ_PlaybackActive", false];
            _display setVariable ["Waldo_MG_SQ_AcceptInput", true];
            { _x ctrlEnable true; } forEach (_display getVariable ["Waldo_MG_SQ_Buttons", []]);
            private _replay = _display getVariable ["Waldo_MG_SQ_ReplayButton", controlNull];
            if (!isNull _replay) then {_replay ctrlEnable !(_display getVariable ["Waldo_MG_SQ_ReplayUsed", false]);};
            private _stage = _display getVariable ["Waldo_MG_SQ_Stage", controlNull];
            if (!isNull _stage) then {_stage ctrlSetText format ["STAGE %1 // YOUR INPUT 0/%2", _display getVariable ["Waldo_MG_SQ_Round", 1], count _sequence];};
            private _inputReadout = _display getVariable ["Waldo_MG_SQ_InputReadout", controlNull];
            if (!isNull _inputReadout) then {_inputReadout ctrlSetText "ENTERED: --";};
            private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
            if (!isNull _status) then {_status ctrlSetText "[INPUT] REPEAT THE AUTHORIZATION SEQUENCE";};
        };
    };
    private _workers = _display getVariable ["Waldo_MG_UI_Workers", []];
    _workers pushBack _worker;
    _display setVariable ["Waldo_MG_UI_Workers", _workers];
}];

_display setVariable ["Waldo_MG_SQ_Activate", {
    params ["_display", "_index"];
    if (isNull _display || {!(_display getVariable ["Waldo_MG_SQ_AcceptInput", false])}) exitWith {};
    private _sequence = _display getVariable ["Waldo_MG_SQ_Sequence", []];
    private _inputIndex = _display getVariable ["Waldo_MG_SQ_InputIndex", 0];
    [_display, _index, true] call (_display getVariable ["Waldo_MG_SQ_ShowControl", {}]);
    private _pulse = [_display, _index] spawn {
        params ["_display", "_index"];
        uiSleep 0.12;
        if (!isNull _display) then {[_display, _index, false] call (_display getVariable ["Waldo_MG_SQ_ShowControl", {}]);};
    };
    private _workers = _display getVariable ["Waldo_MG_UI_Workers", []];
    _workers pushBack _pulse;
    _display setVariable ["Waldo_MG_UI_Workers", _workers];
    if (_index != (_sequence select _inputIndex)) exitWith {
        _display setVariable ["Waldo_MG_SQ_AcceptInput", false];
        [_display, false, "[X] AUTHORIZATION SEQUENCE REJECTED"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
    };
    _inputIndex = _inputIndex + 1;
    _display setVariable ["Waldo_MG_SQ_InputIndex", _inputIndex];
    // Compact redundant identities keep an eight-signal transcript inside the protected readout.
    private _names = ["1:TRI", "2:SQR", "3:DOT", "4:DIA", "5:CRS", "6:HEX"];
    private _entered = _display getVariable ["Waldo_MG_SQ_Entered", []];
    _entered pushBack (_names select _index);
    _display setVariable ["Waldo_MG_SQ_Entered", _entered];
    private _inputReadout = _display getVariable ["Waldo_MG_SQ_InputReadout", controlNull];
    if (!isNull _inputReadout) then {_inputReadout ctrlSetText format ["ENTERED: %1", _entered joinString "  >  "];};
    private _stage = _display getVariable ["Waldo_MG_SQ_Stage", controlNull];
    if (!isNull _stage) then {_stage ctrlSetText format ["STAGE %1 // YOUR INPUT %2/%3", _display getVariable ["Waldo_MG_SQ_Round", 1], _inputIndex, count _sequence];};
    if (_inputIndex < count _sequence) exitWith {};
    _display setVariable ["Waldo_MG_SQ_AcceptInput", false];
    private _round = _display getVariable ["Waldo_MG_SQ_Round", 1];
    private _lamps = _display getVariable ["Waldo_MG_SQ_RoundLamps", []];
    if (_round <= count _lamps) then {
        private _lamp = _lamps select (_round - 1);
        _lamp ctrlSetText format ["%1 [OK]", _round];
        _lamp ctrlSetBackgroundColor [0.18, 0.48, 0.28, 1];
        _lamp ctrlSetTextColor [0.9, 1, 0.9, 1];
    };
    if (_round >= (_display getVariable ["Waldo_MG_SQ_Rounds", 1])) exitWith {
        [_display, true, "[OK] ALL AUTHORIZATION STAGES ACCEPTED"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
    };
    _round = _round + 1;
    _display setVariable ["Waldo_MG_SQ_Round", _round];
    _display setVariable ["Waldo_MG_SQ_ReplayUsed", false];
    _sequence pushBack floor random (_display getVariable ["Waldo_MG_SQ_PadCount", 4]);
    _display setVariable ["Waldo_MG_SQ_Sequence", _sequence];
    [_display] call (_display getVariable ["Waldo_MG_SQ_Play", {}]);
}];

_display setVariable ["Waldo_MG_SQ_Replay", {
    params ["_display"];
    if (!(_display getVariable ["Waldo_MG_SQ_AcceptInput", false]) || {_display getVariable ["Waldo_MG_SQ_ReplayUsed", false]}) exitWith {};
    _display setVariable ["Waldo_MG_SQ_ReplayUsed", true];
    [_display] call (_display getVariable ["Waldo_MG_SQ_Play", {}]);
}];
_replay ctrlAddEventHandler ["ButtonClick", {
    private _display = ctrlParent (_this select 0);
    [_display] call (_display getVariable ["Waldo_MG_SQ_Replay", {}]);
}];

[_display, "KeyDown", {
    params ["_display", "_key"];
    if (_key >= 2 && {_key <= 7}) exitWith {
        private _index = _key - 2;
        if (_index < (_display getVariable ["Waldo_MG_SQ_PadCount", 0])) then {
            [_display, _index] call (_display getVariable ["Waldo_MG_SQ_Activate", {}]);
        };
        true
    };
    if (_key == 19) exitWith {[_display] call (_display getVariable ["Waldo_MG_SQ_Replay", {}]); true};
    false
}] call Waldo_fnc_MiniGameEquipmentAddDisplayHandler;

private _startWorker = [_display] spawn {
    params ["_display"];
    waitUntil {isNull _display || {_display getVariable ["Waldo_IMG_Started", false]}};
    if (!isNull _display) then {[_display] call (_display getVariable ["Waldo_MG_SQ_Play", {}]);};
};
private _workers = _display getVariable ["Waldo_MG_UI_Workers", []];
_workers pushBack _startWorker;
_display setVariable ["Waldo_MG_UI_Workers", _workers];
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

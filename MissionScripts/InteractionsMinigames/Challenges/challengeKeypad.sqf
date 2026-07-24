/*
 * Industrial access-terminal code deduction procedure.
 * Config: [digits(3..6), maxGuesses, timeLimit, title]
 */
disableSerialization;
params [["_config", []], ["_resolve", {}]];
_config params [["_digits", 4], ["_maxGuesses", 6], ["_timeLimit", 0], ["_title", "ACCESS TERMINAL"]];
_digits = ((round _digits) max 3) min 6;
_maxGuesses = (round _maxGuesses) max 1;

private _display = [
    _title,
    "Reconstruct the access code by correlating the authorized digit bank and two recovered security records.",
    _timeLimit,
    _resolve,
    0.50,
    "Mouse or number keys; Backspace removes; Enter submits",
    "SOURCE A gives the prefix. SOURCE B contains the remaining tail in reverse storage order: read it right-to-left. Attempt audit remains available."
] call Waldo_fnc_MiniGameChallengeUI;
if (isNull _display) exitWith {};

private _pool = [0,1,2,3,4,5,6,7,8,9];
private _code = [];
for "_index" from 1 to _digits do {
    private _pick = floor random count _pool;
    _code pushBack (_pool deleteAt _pick);
};
private _digitBank = +_code;
_digitBank sort true;
private _split = ceil (_digits / 2);
private _prefix = _code select [0, _split];
private _reverseTail = _code select [_split];
reverse _reverseTail;
_display setVariable ["Waldo_MG_KP_Code", _code];
_display setVariable ["Waldo_MG_KP_DigitBank", _digitBank];
_display setVariable ["Waldo_MG_KP_Input", []];
_display setVariable ["Waldo_MG_KP_Guesses", 0];
_display setVariable ["Waldo_MG_KP_Digits", _digits];
_display setVariable ["Waldo_MG_KP_MaxGuesses", _maxGuesses];

private _terminal = [_display, "RscText", [1.5, 3, 37, 20], "industrial access terminal casing"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_terminal ctrlSetBackgroundColor [0.12, 0.13, 0.12, 1];
private _screenFrame = [_display, "RscText", [3, 4.2, 22.5, 17.2], "security terminal display bezel"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_screenFrame ctrlSetBackgroundColor [0.035, 0.045, 0.04, 1];
private _screen = [_display, "RscText", [3.8, 5, 20.9, 15.6], "security terminal display"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_screen ctrlSetBackgroundColor [0.005, 0.02, 0.014, 1];
private _lockState = [_display, "RscText", [4.5, 5.7, 19.5, 1.4], "terminal lock state"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_lockState ctrlSetText "[LOCKED] SECURITY SEAL ACTIVE";
_lockState ctrlSetTextColor [1, 0.64, 0.72, 1];
_lockState ctrlSetBackgroundColor [0.16, 0.025, 0.045, 1];
_display setVariable ["Waldo_MG_KP_LockState", _lockState];
private _bank = [_display, "RscText", [5, 7.2, 18.5, 1.15], "authorized digit bank"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_bank ctrlSetText format ["AUTHORIZED DIGITS // %1 // USE EACH ONCE", _digitBank joinString "  "];
_bank ctrlSetTextColor [0.94, 0.78, 0.30, 1];
_bank ctrlSetBackgroundColor [0.05, 0.045, 0.015, 1];
private _readout = [_display, "RscText", [5, 8.45, 18.5, 2.35], "current access code entry"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_readout ctrlSetText "";
_readout ctrlSetTextColor [0.58, 1, 0.70, 1];
_readout ctrlSetBackgroundColor [0.008, 0.03, 0.018, 1];
_readout ctrlSetFontHeight 0.038;
_display setVariable ["Waldo_MG_KP_Readout", _readout];
private _feedbackHeader = [_display, "RscText", [5, 11, 18.5, 1.15], "guess feedback headings"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_feedbackHeader ctrlSetText "RECOVERED SECURITY EVIDENCE";
_feedbackHeader ctrlSetTextColor [0.94, 0.78, 0.30, 1];
private _evidence = [_display, "RscStructuredText", [5, 12.2, 18.5, 2.55], "two guaranteed access code evidence sources"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_evidence ctrlSetStructuredText parseText format ["<t color='#9FDDB0'>SOURCE A // PREFIX SLOTS 1-%1:</t> <t color='#FFFFFF'>%2</t><br/><t color='#9FDDB0'>SOURCE B // REVERSED TAIL:</t> <t color='#FFFFFF'>%3</t> <t color='#F2BE55'>(READ RIGHT-TO-LEFT)</t>", _split, _prefix joinString "  ", _reverseTail joinString "  "];
_evidence ctrlSetBackgroundColor [0.012, 0.035, 0.02, 1];
private _feedbackDetail = [_display, "RscText", [5, 14.95, 18.5, 1.45], "latest access audit clue"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_feedbackDetail ctrlSetText "EXACT SLOTS: --  //  MISPLACED DIGITS: --";
_feedbackDetail ctrlSetTextColor [0.72, 0.90, 0.76, 1];
_feedbackDetail ctrlSetBackgroundColor [0.012, 0.035, 0.02, 1];
_display setVariable ["Waldo_MG_KP_FeedbackDetail", _feedbackDetail];
private _history = [_display, "RscListbox", [5, 16.55, 18.5, 2.4], "access attempt history"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_display setVariable ["Waldo_MG_KP_History", _history];
private _legend = [_display, "RscText", [5, 19.1, 18.5, 1.3], "attempt count"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_legend ctrlSetText format ["ATTEMPTS 0 / %1", _maxGuesses];
_legend ctrlSetTextColor [0.74, 0.78, 0.72, 1];
_display setVariable ["Waldo_MG_KP_Attempts", _legend];

private _keypadBay = [_display, "RscText", [27, 4.2, 10.5, 17.2], "sealed physical keypad"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_keypadBay ctrlSetBackgroundColor [0.045, 0.05, 0.047, 1];
private _seal = [_display, "RscText", [27.8, 4.8, 8.9, 1.2], "security seal label"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_seal ctrlSetText "IX-4 // TAMPER SEALED";
_seal ctrlSetTextColor [0.72, 0.74, 0.66, 1];
private _keys = [];
private _keyValues = [1,2,3,4,5,6,7,8,9,-2,0,-1];
for "_keyIndex" from 0 to 11 do {
    private _column = _keyIndex mod 3;
    private _row = floor (_keyIndex / 3);
    private _value = _keyValues select _keyIndex;
    private _label = if (_value == -2) then {"BACK"} else {if (_value == -1) then {"ENTER"} else {str _value}};
    private _semantic = if (_value == -2) then {"backspace remove digit"} else {if (_value == -1) then {"submit access code"} else {format ["keypad digit %1", _value]}};
    private _key = [_display, "RscButton", [28 + (_column * 2.9), 6.5 + (_row * 3.25), 2.55, 2.75], _semantic] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _key ctrlSetText _label;
    _key ctrlSetBackgroundColor (if (_value < 0) then {[0.22, 0.18, 0.10, 1]} else {[0.13, 0.15, 0.14, 1]});
    _key ctrlSetTooltip _semantic;
    _key setVariable ["Waldo_MG_KP_Value", _value];
    _key ctrlAddEventHandler ["ButtonClick", {
        params ["_control"];
        private _display = ctrlParent _control;
        [_display, _control getVariable ["Waldo_MG_KP_Value", -99]] call (_display getVariable ["Waldo_MG_KP_Action", {}]);
    }];
    _keys pushBack _key;
    if (_value == -2) then {_display setVariable ["Waldo_MG_KP_Backspace", _key];};
    if (_value == -1) then {_display setVariable ["Waldo_MG_KP_Enter", _key];};
};
_display setVariable ["Waldo_MG_KP_Keys", _keys];

_display setVariable ["Waldo_MG_KP_Refresh", {
    params ["_display"];
    private _input = _display getVariable ["Waldo_MG_KP_Input", []];
    private _digits = _display getVariable ["Waldo_MG_KP_Digits", 4];
    private _characters = [];
    for "_index" from 0 to (_digits - 1) do {_characters pushBack (if (_index < count _input) then {str (_input select _index)} else {"_"});};
    private _readout = _display getVariable ["Waldo_MG_KP_Readout", controlNull];
    if (!isNull _readout) then {_readout ctrlSetText format ["CODE  %1", _characters joinString "  "];};
    private _back = _display getVariable ["Waldo_MG_KP_Backspace", controlNull];
    if (!isNull _back) then {_back ctrlEnable (count _input > 0); _back ctrlSetTooltip (if (count _input > 0) then {"Remove the last digit"} else {"Disabled: no digit to remove"});};
    private _enter = _display getVariable ["Waldo_MG_KP_Enter", controlNull];
    if (!isNull _enter) then {_enter ctrlEnable (count _input == _digits); _enter ctrlSetTooltip (if (count _input == _digits) then {"Submit the entered code"} else {format ["Disabled: enter %1 more digit(s)", _digits - count _input]});};
    private _bank = _display getVariable ["Waldo_MG_KP_DigitBank", []];
    {
        private _value = _x getVariable ["Waldo_MG_KP_Value", -99];
        if (_value >= 0) then {
            private _available = _value in _bank && {!(_value in _input)};
            _x ctrlEnable _available;
            _x ctrlSetTooltip (if (!(_value in _bank)) then {"Disabled: digit is not in the authorized bank"} else {if (_value in _input) then {"Disabled: each authorized digit is used once"} else {format ["Enter authorized digit %1", _value]}});
        };
    } forEach (_display getVariable ["Waldo_MG_KP_Keys", []]);
}];
_display setVariable ["Waldo_MG_KP_Action", {
    params ["_display", "_value"];
    if (!(_display getVariable ["Waldo_IMG_Started", false]) || {_display getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
    private _input = _display getVariable ["Waldo_MG_KP_Input", []];
    private _digits = _display getVariable ["Waldo_MG_KP_Digits", 4];
    if (_value >= 0) exitWith {
        private _bank = _display getVariable ["Waldo_MG_KP_DigitBank", []];
        if (count _input < _digits && {_value in _bank} && {!(_value in _input)}) then {_input pushBack _value; _display setVariable ["Waldo_MG_KP_Input", _input]; [_display] call (_display getVariable ["Waldo_MG_KP_Refresh", {}]);};
    };
    if (_value == -2) exitWith {
        if (count _input > 0) then {_input deleteAt ((count _input) - 1); _display setVariable ["Waldo_MG_KP_Input", _input]; [_display] call (_display getVariable ["Waldo_MG_KP_Refresh", {}]);};
    };
    if (_value != -1 || {count _input != _digits}) exitWith {};
    private _code = _display getVariable ["Waldo_MG_KP_Code", []];
    private _exact = 0;
    private _exactSlots = [];
    private _codeRemainder = [];
    private _guessRemainder = [];
    for "_index" from 0 to (_digits - 1) do {
        if ((_input select _index) == (_code select _index)) then {_exact = _exact + 1; _exactSlots pushBack (_index + 1);} else {
            _codeRemainder pushBack (_code select _index);
            _guessRemainder pushBack (_input select _index);
        };
    };
    private _misplaced = 0;
    private _misplacedDigits = [];
    {
        private _found = _codeRemainder find _x;
        if (_found >= 0) then {_misplaced = _misplaced + 1; _misplacedDigits pushBack _x; _codeRemainder deleteAt _found;};
    } forEach _guessRemainder;
    private _guesses = (_display getVariable ["Waldo_MG_KP_Guesses", 0]) + 1;
    _display setVariable ["Waldo_MG_KP_Guesses", _guesses];
    private _history = _display getVariable ["Waldo_MG_KP_History", controlNull];
    if (!isNull _history) then {
        private _row = _history lbAdd format ["%1  //  SLOTS %2  //  MOVED %3", _input joinString "", if (_exactSlots isEqualTo []) then {"--"} else {_exactSlots joinString ","}, if (_misplacedDigits isEqualTo []) then {"--"} else {_misplacedDigits joinString ","}];
        _history lbSetTooltip [_row, format ["Attempt %1: exact slots %2; misplaced digits %3", _guesses, _exactSlots, _misplacedDigits]];
        _history lbSetCurSel _row;
    };
    private _detail = _display getVariable ["Waldo_MG_KP_FeedbackDetail", controlNull];
    if (!isNull _detail) then {
        _detail ctrlSetText format ["EXACT SLOTS: %1  //  MISPLACED DIGITS: %2", if (_exactSlots isEqualTo []) then {"--"} else {_exactSlots joinString ", "}, if (_misplacedDigits isEqualTo []) then {"--"} else {_misplacedDigits joinString ", "}];
    };
    private _attempts = _display getVariable ["Waldo_MG_KP_Attempts", controlNull];
    if (!isNull _attempts) then {_attempts ctrlSetText format ["ATTEMPTS %1 / %2", _guesses, _display getVariable ["Waldo_MG_KP_MaxGuesses", 1]];};
    if (_exact == _digits) exitWith {
        private _lock = _display getVariable ["Waldo_MG_KP_LockState", controlNull];
        if (!isNull _lock) then {_lock ctrlSetText "[OPEN] ACCESS GRANTED"; _lock ctrlSetBackgroundColor [0.08, 0.30, 0.15, 1];};
        [_display, true, "[OK] ACCESS CODE ACCEPTED"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
    };
    if (_guesses >= (_display getVariable ["Waldo_MG_KP_MaxGuesses", 1])) exitWith {
        [_display, false, format ["[X] SECURITY LOCKOUT // CODE %1", _code joinString ""]] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
    };
    _display setVariable ["Waldo_MG_KP_Input", []];
    private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then {_status ctrlSetText format ["[AUDIT] EXACT %1 // MISPLACED %2", _exact, _misplaced];};
    [_display] call (_display getVariable ["Waldo_MG_KP_Refresh", {}]);
}];

[_display, "KeyDown", {
    params ["_display", "_key"];
    private _value = switch (_key) do {
        case 2: {1}; case 3: {2}; case 4: {3}; case 5: {4}; case 6: {5};
        case 7: {6}; case 8: {7}; case 9: {8}; case 10: {9}; case 11: {0};
        case 14: {-2}; case 28: {-1}; default {-99};
    };
    if (_value != -99) exitWith {[_display, _value] call (_display getVariable ["Waldo_MG_KP_Action", {}]); true};
    false
}] call Waldo_fnc_MiniGameEquipmentAddDisplayHandler;
[_display] call (_display getVariable ["Waldo_MG_KP_Refresh", {}]);
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

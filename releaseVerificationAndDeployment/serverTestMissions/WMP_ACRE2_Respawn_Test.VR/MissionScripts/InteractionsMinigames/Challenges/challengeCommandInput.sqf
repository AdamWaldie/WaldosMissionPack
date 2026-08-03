/*
 * Tactical directional-command uplink procedure.
 * Config: [baseLength(3..8), rounds(1..6), maxMistakes(1..6), timeLimit, title]
 */
disableSerialization;
params [["_config", []], ["_resolve", {}]];
_config params [["_baseLength", 4], ["_rounds", 3], ["_maxMistakes", 3], ["_timeLimit", 45], ["_title", "TACTICAL UPLINK"]];
_baseLength = ((round _baseLength) max 3) min 8;
_rounds = ((round _rounds) max 1) min 6;
_maxMistakes = ((round _maxMistakes) max 1) min 6;

private _display = [
    _title,
    "Enter each displayed directional command in order to authorize the requested support channel.",
    _timeLimit,
    _resolve,
    0.49,
    "Keyboard arrow keys or the four labelled direction controls",
    "Read the highlighted command from left to right. An incorrect direction resets the current packet and records a fault."
] call Waldo_fnc_MiniGameChallengeUI;
if (isNull _display) exitWith {};

_display setVariable ["Waldo_MG_CI_BaseLength", _baseLength];
_display setVariable ["Waldo_MG_CI_Round", 1];
_display setVariable ["Waldo_MG_CI_Rounds", _rounds];
_display setVariable ["Waldo_MG_CI_MaxMistakes", _maxMistakes];
_display setVariable ["Waldo_MG_CI_Mistakes", 0];
_display setVariable ["Waldo_MG_CI_InputIndex", 0];
_display setVariable ["Waldo_MG_CI_AcceptInput", true];

private _directions = [
    ["UP", "[^]", 200],
    ["RIGHT", "[>]", 205],
    ["DOWN", "[v]", 208],
    ["LEFT", "[<]", 203]
];
_display setVariable ["Waldo_MG_CI_Directions", _directions];

private _terminal = [_display, "RscText", [1.5, 3, 37, 20], "tactical command uplink casing"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_terminal ctrlSetBackgroundColor [0.10, 0.12, 0.13, 1];
private _header = [_display, "RscText", [2.5, 3.7, 35, 1.45], "uplink procedure header"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_header ctrlSetText "DIRECTIONAL AUTHORIZATION // READ LEFT TO RIGHT // INPUT HIGHLIGHTED COMMAND";
_header ctrlSetBackgroundColor [0.02, 0.035, 0.035, 1];
_header ctrlSetTextColor [0.42, 0.88, 0.78, 1];
_header ctrlSetFontHeight 0.026;

private _packetReadout = [_display, "RscText", [2.8, 5.5, 21, 1.35], "command packet progress"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_packetReadout ctrlSetText format ["PACKET 1/%1 // COMMAND 1/%2", _rounds, _baseLength];
_packetReadout ctrlSetBackgroundColor [0.015, 0.03, 0.028, 1];
_packetReadout ctrlSetTextColor [0.92, 0.92, 0.86, 1];
_display setVariable ["Waldo_MG_CI_PacketReadout", _packetReadout];
private _faultReadout = [_display, "RscText", [24.2, 5.5, 13, 1.35], "command fault count"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_faultReadout ctrlSetText format ["FAULTS 0/%1", _maxMistakes];
_faultReadout ctrlSetBackgroundColor [0.015, 0.03, 0.028, 1];
_faultReadout ctrlSetTextColor [0.96, 0.78, 0.30, 1];
_display setVariable ["Waldo_MG_CI_FaultReadout", _faultReadout];

private _commandBay = [_display, "RscText", [2.5, 7.15, 35, 6.45], "directional command packet display"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_commandBay ctrlSetBackgroundColor [0.025, 0.04, 0.04, 1];
private _cells = [];
for "_index" from 0 to 12 do {
    private _column = _index mod 7;
    private _row = floor (_index / 7);
    private _cell = [_display, "RscText", [3.1 + (_column * 4.85), 7.8 + (_row * 2.65), 4.4, 2.15], format ["direction command %1", _index + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _cell ctrlSetBackgroundColor [0.11, 0.14, 0.14, 1];
    _cell ctrlSetTextColor [0.78, 0.82, 0.78, 1];
    _cell ctrlSetFontHeight 0.040;
    _cell ctrlShow false;
    _cells pushBack _cell;
};
_display setVariable ["Waldo_MG_CI_Cells", _cells];

private _instruction = [_display, "RscText", [3, 14.1, 13.2, 1.25], "current command instruction"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_instruction ctrlSetText "ENTER THE HIGHLIGHTED COMMAND";
_instruction ctrlSetTextColor [0.96, 0.78, 0.30, 1];
_display setVariable ["Waldo_MG_CI_Instruction", _instruction];
private _transcript = [_display, "RscText", [3, 15.45, 13.2, 5.75], "entered direction transcript"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_transcript ctrlSetText "ENTERED 0/0 // LAST --";
_transcript ctrlSetBackgroundColor [0.02, 0.035, 0.035, 1];
_transcript ctrlSetTextColor [0.76, 0.82, 0.78, 1];
_display setVariable ["Waldo_MG_CI_Transcript", _transcript];

private _controlBank = [_display, "RscText", [17.15, 14.25, 20.2, 7.35], "directional input control bank"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_controlBank ctrlSetBackgroundColor [0.035, 0.05, 0.05, 1];
private _buttons = [];
// A fixed 2x2 bank avoids the D-pad cross colliding with the instruction and
// transcript at large Arma UI scales. Direction names preserve the spatial cue.
private _buttonRects = [[18.0, 14.9, 8.7, 2.65], [27.8, 14.9, 8.7, 2.65], [27.8, 18.25, 8.7, 2.65], [18.0, 18.25, 8.7, 2.65]];
{
    _x params ["_name", "_symbol"];
    private _button = [_display, "RscButton", _buttonRects select _forEachIndex, format ["%1 direction command", toLower _name]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _button ctrlSetText format ["%1  %2", _symbol, _name];
    _button ctrlSetFontHeight 0.030;
    _button ctrlSetBackgroundColor [0.16, 0.20, 0.20, 1];
    _button ctrlSetTooltip format ["Enter %1; keyboard %1 arrow", _name];
    _button setVariable ["Waldo_MG_CI_Direction", _forEachIndex];
    _button ctrlAddEventHandler ["ButtonClick", {
        params ["_control"];
        private _display = ctrlParent _control;
        [_display, _control getVariable ["Waldo_MG_CI_Direction", -1]] call (_display getVariable ["Waldo_MG_CI_Activate", {}]);
    }];
    _buttons pushBack _button;
} forEach _directions;
_display setVariable ["Waldo_MG_CI_Buttons", _buttons];

_display setVariable ["Waldo_MG_CI_NewPacket", {
    params ["_display"];
    private _round = _display getVariable ["Waldo_MG_CI_Round", 1];
    private _length = ((_display getVariable ["Waldo_MG_CI_BaseLength", 4]) + _round - 1) min 13;
    private _packet = [];
    for "_index" from 1 to _length do {_packet pushBack floor random 4;};
    _display setVariable ["Waldo_MG_CI_Packet", _packet];
    _display setVariable ["Waldo_MG_CI_InputIndex", 0];
    _display setVariable ["Waldo_MG_CI_Entered", []];
    _display setVariable ["Waldo_MG_CI_AcceptInput", true];
    private _directions = _display getVariable ["Waldo_MG_CI_Directions", []];
    {
        if (_forEachIndex < _length) then {
            private _identity = _directions select (_packet select _forEachIndex);
            _x ctrlShow true;
            _x ctrlSetText (_identity select 1);
            _x ctrlSetBackgroundColor (if (_forEachIndex == 0) then {[0.82, 0.66, 0.20, 1]} else {[0.11, 0.14, 0.14, 1]});
            _x ctrlSetTextColor (if (_forEachIndex == 0) then {[0.04, 0.05, 0.04, 1]} else {[0.78, 0.82, 0.78, 1]});
        } else {
            _x ctrlShow false;
        };
    } forEach (_display getVariable ["Waldo_MG_CI_Cells", []]);
    private _readout = _display getVariable ["Waldo_MG_CI_PacketReadout", controlNull];
    if (!isNull _readout) then {_readout ctrlSetText format ["PACKET %1/%2 // COMMAND 1/%3", _round, _display getVariable ["Waldo_MG_CI_Rounds", 1], _length];};
    private _transcript = _display getVariable ["Waldo_MG_CI_Transcript", controlNull];
    if (!isNull _transcript) then {_transcript ctrlSetText format ["ENTERED 0/%1 // LAST --", _length];};
    private _instruction = _display getVariable ["Waldo_MG_CI_Instruction", controlNull];
    if (!isNull _instruction && {_packet isNotEqualTo []}) then {
        private _first = _directions select (_packet select 0);
        _instruction ctrlSetText format ["NEXT // %1 %2", _first select 1, _first select 0];
    };
    private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then {_status ctrlSetText format ["[INPUT] PACKET %1/%2 // ENTER COMMAND 1/%3", _round, _display getVariable ["Waldo_MG_CI_Rounds", 1], _length];};
}];

_display setVariable ["Waldo_MG_CI_Activate", {
    params ["_display", "_direction"];
    if (isNull _display || {!(_display getVariable ["Waldo_IMG_Started", false])} || {!(_display getVariable ["Waldo_MG_CI_AcceptInput", false])}) exitWith {};
    private _packet = _display getVariable ["Waldo_MG_CI_Packet", []];
    private _index = _display getVariable ["Waldo_MG_CI_InputIndex", 0];
    if (_direction < 0 || {_index >= count _packet}) exitWith {};
    if (_direction != (_packet select _index)) exitWith {
        private _mistakes = (_display getVariable ["Waldo_MG_CI_Mistakes", 0]) + 1;
        _display setVariable ["Waldo_MG_CI_Mistakes", _mistakes];
        private _fault = _display getVariable ["Waldo_MG_CI_FaultReadout", controlNull];
        if (!isNull _fault) then {_fault ctrlSetText format ["FAULTS %1/%2 // [X] RESET", _mistakes, _display getVariable ["Waldo_MG_CI_MaxMistakes", 1]];};
        if (_mistakes >= (_display getVariable ["Waldo_MG_CI_MaxMistakes", 1])) exitWith {
            [_display, false, "[X] COMMAND AUTHORIZATION LOCKED"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
        };
        [_display] call (_display getVariable ["Waldo_MG_CI_NewPacket", {}]);
        private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
        if (!isNull _status) then {_status ctrlSetText "[X] WRONG DIRECTION // CURRENT PACKET RESET TO COMMAND 1";};
    };
    private _cells = _display getVariable ["Waldo_MG_CI_Cells", []];
    private _directions = _display getVariable ["Waldo_MG_CI_Directions", []];
    private _cell = _cells select _index;
    private _identity = _directions select _direction;
    _cell ctrlSetText format ["[OK] %1", _identity select 1];
    _cell ctrlSetFontHeight 0.030;
    _cell ctrlSetBackgroundColor [0.14, 0.42, 0.26, 1];
    _cell ctrlSetTextColor [0.90, 1, 0.92, 1];
    private _entered = _display getVariable ["Waldo_MG_CI_Entered", []];
    _entered pushBack (_identity select 1);
    _display setVariable ["Waldo_MG_CI_Entered", _entered];
    _index = _index + 1;
    _display setVariable ["Waldo_MG_CI_InputIndex", _index];
    private _transcript = _display getVariable ["Waldo_MG_CI_Transcript", controlNull];
    if (!isNull _transcript) then {_transcript ctrlSetText format ["ENTERED %1/%2 // LAST %3 %4", _index, count _packet, _identity select 1, _identity select 0];};
    private _readout = _display getVariable ["Waldo_MG_CI_PacketReadout", controlNull];
    if (!isNull _readout) then {_readout ctrlSetText format ["PACKET %1/%2 // COMMAND %3/%4", _display getVariable ["Waldo_MG_CI_Round", 1], _display getVariable ["Waldo_MG_CI_Rounds", 1], (_index + 1) min count _packet, count _packet];};
    if (_index < count _packet) exitWith {
        private _next = _cells select _index;
        _next ctrlSetBackgroundColor [0.82, 0.66, 0.20, 1];
        _next ctrlSetTextColor [0.04, 0.05, 0.04, 1];
        private _nextIdentity = _directions select (_packet select _index);
        private _instruction = _display getVariable ["Waldo_MG_CI_Instruction", controlNull];
        if (!isNull _instruction) then {_instruction ctrlSetText format ["NEXT // %1 %2", _nextIdentity select 1, _nextIdentity select 0];};
    };
    _display setVariable ["Waldo_MG_CI_AcceptInput", false];
    private _round = _display getVariable ["Waldo_MG_CI_Round", 1];
    if (_round >= (_display getVariable ["Waldo_MG_CI_Rounds", 1])) exitWith {
        [_display, true, "[OK] SUPPORT CHANNEL AUTHORIZED"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
    };
    _display setVariable ["Waldo_MG_CI_Round", _round + 1];
    private _worker = [_display] spawn {
        params ["_display"];
        private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
        if (!isNull _status) then {_status ctrlSetText "[OK] COMMAND PACKET ACCEPTED // LOADING NEXT PACKET";};
        uiSleep 0.55;
        if (!isNull _display && {!(_display getVariable ["Waldo_MG_UI_Done", false])}) then {[_display] call (_display getVariable ["Waldo_MG_CI_NewPacket", {}]);};
    };
    private _workers = _display getVariable ["Waldo_MG_UI_Workers", []];
    _workers pushBack _worker;
    _display setVariable ["Waldo_MG_UI_Workers", _workers];
}];

[_display, "KeyDown", {
    params ["_display", "_key"];
    private _direction = switch (_key) do {
        case 200: {0};
        case 205: {1};
        case 208: {2};
        case 203: {3};
        default {-1};
    };
    if (_direction >= 0) exitWith {[_display, _direction] call (_display getVariable ["Waldo_MG_CI_Activate", {}]); true};
    false
}] call Waldo_fnc_MiniGameEquipmentAddDisplayHandler;

[_display] call (_display getVariable ["Waldo_MG_CI_NewPacket", {}]);
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

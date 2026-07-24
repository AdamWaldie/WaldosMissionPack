/*
 * Rugged EOD controller wire-isolation procedure.
 * Config: [wireCount(3..6), timeLimit, title, verificationLevel(1..4, derived)]
 */
disableSerialization;
params [["_config", []], ["_resolve", {}]];
_config params [["_wireCount", 5], ["_timeLimit", 20], ["_title", "EOD CONTROLLER"], ["_verificationLevel", -1]];
_wireCount = ((round _wireCount) max 3) min 6;
if (_verificationLevel < 1) then {_verificationLevel = switch (_wireCount) do {case 3: {1}; case 4: {2}; case 5: {3}; default {4};};};
_verificationLevel = ((round _verificationLevel) max 1) min 4;

private _display = [
    _title,
    "Cross-check the isolation order against the loom labels, insulation, continuity and routed bus, then sever it.",
    _timeLimit,
    _resolve,
    0.48,
    "Select loom; TEST CONTINUITY acquires its live reading; verify order; arm cutter",
    "Higher-density controllers require several independent readings. The cutter remains mechanically safe until the selected loom has been probed."
] call Waldo_fnc_MiniGameChallengeUI;
if (isNull _display) exitWith {};

private _identities = [
    ["J1", "SOLID", "LIVE", "BUS A", [0.28, 0.58, 0.86, 1]],
    ["J1", "DASH", "OPEN", "BUS B", [0.88, 0.36, 0.30, 1]],
    ["J2", "SOLID", "PULSE", "BUS B", [0.30, 0.68, 0.38, 1]],
    ["J2", "DASH", "LIVE", "BUS C", [0.88, 0.68, 0.22, 1]],
    ["J3", "DOT", "OPEN", "BUS A", [0.62, 0.40, 0.76, 1]],
    ["J3", "DOT", "PULSE", "BUS C", [0.26, 0.70, 0.72, 1]]
];
private _correct = floor random _wireCount;
private _correctIdentity = _identities select _correct;
private _orderText = switch (_verificationLevel) do {
    case 1: {format ["ISOLATE BAY %1", _correct + 1]};
    case 2: {format ["MATCH %1 CONNECTOR // %2 INSULATION", _correctIdentity select 0, _correctIdentity select 1]};
    case 3: {format ["MATCH %1 INSULATION // %2 CONTINUITY // %3", _correctIdentity select 1, _correctIdentity select 2, _correctIdentity select 3]};
    default {format ["MATCH %1 // %2 // %3 // %4", _correctIdentity select 0, _correctIdentity select 1, _correctIdentity select 2, _correctIdentity select 3]};
};
private _verificationCount = _verificationLevel;
_display setVariable ["Waldo_MG_WC_Correct", _correct];
_display setVariable ["Waldo_MG_WC_Selected", -1];
_display setVariable ["Waldo_MG_WC_Probed", -1];

private _case = [_display, "RscText", [1.5, 3, 37, 20], "reinforced EOD controller casing"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_case ctrlSetBackgroundColor [0.13, 0.14, 0.12, 1];
private _instructionFrame = [_display, "RscText", [2.6, 4, 35, 4.4], "EOD isolation instruction card"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_instructionFrame ctrlSetBackgroundColor [0.76, 0.72, 0.57, 1];
private _instruction = [_display, "RscStructuredText", [3.4, 4.35, 19.5, 3.8], "required wire instruction"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_instruction ctrlSetStructuredText parseText format [
    "<t color='#202018' size='0.90'>EOD-7 ISOLATION ORDER // %2-POINT VERIFICATION</t><br/><t color='#8A1E24' size='1.08'>%1</t><br/><t color='#202018' size='0.86'>READ LABELS; DO NOT RELY ON COLOUR</t>",
    _orderText,
    _verificationCount
];
private _probeButton = [_display, "RscButton", [23.6, 4.55, 6.2, 1.45], "EOD continuity probe control"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_probeButton ctrlSetText "PROBE SAFE - SELECT";
_probeButton ctrlSetBackgroundColor [0.08, 0.16, 0.16, 1];
_probeButton ctrlSetTextColor [0.48, 0.86, 0.84, 1];
_probeButton ctrlSetTooltip "Select a loom before testing continuity";
_probeButton ctrlEnable false;
_display setVariable ["Waldo_MG_WC_ProbeButton", _probeButton];
private _diagnostic = [_display, "RscText", [23.6, 6.25, 6.2, 1.35], "EOD continuity probe diagnostic"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_diagnostic ctrlSetText "CONTINUITY // --";
_diagnostic ctrlSetBackgroundColor [0.015, 0.045, 0.04, 1];
_diagnostic ctrlSetTextColor [0.48, 0.86, 0.84, 1];
_display setVariable ["Waldo_MG_WC_Diagnostic", _diagnostic];
private _cutButton = [_display, "RscButton", [30.3, 4.75, 6.2, 2.8], "guarded EOD cutter control"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_cutButton ctrlSetText "CUTTER SAFE - SELECT LOOM";
_cutButton ctrlSetBackgroundColor [0.18, 0.16, 0.08, 1];
_cutButton ctrlSetTextColor [0.96, 0.78, 0.30, 1];
_cutButton ctrlSetTooltip "Disabled: inspect and select a wire loom first";
_cutButton ctrlEnable false;
_display setVariable ["Waldo_MG_WC_CutButton", _cutButton];

private _loomBay = [_display, "RscText", [3, 9, 34, 11.8], "numbered wire loom bay"] call Waldo_fnc_MiniGameEquipmentCreateControl;
_loomBay ctrlSetBackgroundColor [0.035, 0.042, 0.038, 1];
private _rowHeight = 10.2 / _wireCount;
private _wireSegments = [];
private _buttons = [];
for "_index" from 0 to (_wireCount - 1) do {
    private _identity = _identities select _index;
    private _rowY = 9.8 + (_index * _rowHeight);
    private _leftConnector = [_display, "RscText", [3.8, _rowY, 4.2, _rowHeight - 0.35], format ["left connector %1", _identity select 0]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _leftConnector ctrlSetText format ["%1 <%2>", _identity select 0, _identity select 1];
    _leftConnector ctrlSetBackgroundColor [0.16, 0.17, 0.15, 1];
    _leftConnector ctrlSetTextColor [0.94, 0.91, 0.80, 1];
    private _rightConnector = [_display, "RscText", [32, _rowY, 4.2, _rowHeight - 0.35], format ["continuity and bus for bay %1", _index + 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _rightConnector ctrlSetText format ["%1 | B%2", _identity select 3, _index + 1];
    _rightConnector ctrlSetBackgroundColor [0.16, 0.17, 0.15, 1];
    _rightConnector ctrlSetTextColor [0.94, 0.91, 0.80, 1];
    private _points = [[8, _rowY + ((_rowHeight - 0.35) / 2)], [32, _rowY + ((_rowHeight - 0.35) / 2)]];
    private _segments = [_display, _points, _identity select 4, 0.26, format ["wire %1 %2 insulation", _identity select 0, _identity select 1]] call Waldo_fnc_MiniGameEquipmentPolyline;
    // Redundant insulation patterns are rendered as bright markers along the loom.
    private _patternSegments = [];
    private _patternIndex = ["SOLID", "DASH", "DOT"] find (_identity select 1);
    private _patternStep = switch (_patternIndex) do {case 0: {2.2}; case 1: {1.5}; default {1.0};};
    private _markerX = 9;
    while {_markerX < 31.5} do {
        private _markerWidth = if (_patternIndex == 0) then {0.28} else {if (_patternIndex == 1) then {0.5} else {0.22}};
        private _marker = [_display, "RscText", [_markerX, _rowY + ((_rowHeight - 0.35) / 2) - 0.23, _markerWidth, 0.46], format ["wire %1 printed %2 marker", _identity select 0, _identity select 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
        _marker ctrlSetBackgroundColor [0.92, 0.92, 0.82, 0.92];
        _patternSegments pushBack _marker;
        _markerX = _markerX + _patternStep;
    };
    _wireSegments pushBack [_segments, _patternSegments];
    // Keep the wire and its printed pattern unobscured. The compact guarded
    // selector is still a generous target, while the connector and pattern
    // remain visible beside it.
    private _button = [_display, "RscButton", [26.8, _rowY - 0.15, 5.2, _rowHeight - 0.05], format ["cut wire %1 %2", _identity select 0, _identity select 1]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _button ctrlSetText format ["SELECT %1", _index + 1];
    _button ctrlSetBackgroundColor [0.10, 0.11, 0.10, 0.96];
    _button ctrlSetTextColor [0.95, 0.95, 0.90, 1];
    _button ctrlSetTooltip format ["Bay %1: %2 connector, %3 insulation, %4 continuity, %5", _index + 1, _identity select 0, _identity select 1, _identity select 2, _identity select 3];
    _button setVariable ["Waldo_MG_WC_Index", _index];
    _button ctrlAddEventHandler ["MouseEnter", {(_this select 0) ctrlSetBackgroundColor [0.75, 0.62, 0.20, 0.18];}];
    _button ctrlAddEventHandler ["MouseExit", {(_this select 0) ctrlSetBackgroundColor [0, 0, 0, 0.01];}];
    _button ctrlAddEventHandler ["ButtonClick", {
        params ["_control"];
        private _display = ctrlParent _control;
        private _index = _control getVariable ["Waldo_MG_WC_Index", -1];
        [_display, _index] call (_display getVariable ["Waldo_MG_WC_Select", {}]);
    }];
    _buttons pushBack _button;
};
_display setVariable ["Waldo_MG_WC_WireSegments", _wireSegments];
_display setVariable ["Waldo_MG_WC_Buttons", _buttons];
_display setVariable ["Waldo_MG_WC_Identities", _identities];
_display setVariable ["Waldo_MG_WC_Select", {
    params ["_display", "_index"];
    if (!(_display getVariable ["Waldo_IMG_Started", false]) || {_display getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
    private _identities = _display getVariable ["Waldo_MG_WC_Identities", []];
    if (_index < 0 || {_index >= count _identities}) exitWith {};
    _display setVariable ["Waldo_MG_WC_Selected", _index];
    _display setVariable ["Waldo_MG_WC_Probed", -1];
    {
        _x ctrlSetBackgroundColor (if (_forEachIndex == _index) then {[0.46, 0.36, 0.08, 0.96]} else {[0.10, 0.11, 0.10, 0.96]});
        _x ctrlSetText format ["%1 %2", if (_forEachIndex == _index) then {"[ON]"} else {"SELECT"}, _forEachIndex + 1];
    } forEach (_display getVariable ["Waldo_MG_WC_Buttons", []]);
    private _identity = _identities select _index;
    private _probe = _display getVariable ["Waldo_MG_WC_ProbeButton", controlNull];
    if (!isNull _probe) then {
        _probe ctrlEnable true;
        _probe ctrlSetText format ["TEST CONTINUITY // B%1", _index + 1];
        _probe ctrlSetTooltip format ["Attach continuity probe to selected bay %1", _index + 1];
    };
    private _diagnostic = _display getVariable ["Waldo_MG_WC_Diagnostic", controlNull];
    if (!isNull _diagnostic) then {_diagnostic ctrlSetText format ["BAY %1 // NOT TESTED", _index + 1];};
    private _cutter = _display getVariable ["Waldo_MG_WC_CutButton", controlNull];
    if (!isNull _cutter) then {
        _cutter ctrlEnable false;
        _cutter ctrlSetText "CUTTER SAFE // PROBE FIRST";
        _cutter ctrlSetTooltip "Disabled: acquire continuity from the selected loom first";
    };
    private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then {_status ctrlSetText format ["[STEP 2/3] BAY %1 SELECTED // ATTACH CONTINUITY PROBE", _index + 1];};
}];
_display setVariable ["Waldo_MG_WC_ProbeSelected", {
    params ["_display"];
    if (!(_display getVariable ["Waldo_IMG_Started", false]) || {_display getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
    private _index = _display getVariable ["Waldo_MG_WC_Selected", -1];
    if (_index < 0) exitWith {};
    private _identity = (_display getVariable ["Waldo_MG_WC_Identities", []]) select _index;
    _display setVariable ["Waldo_MG_WC_Probed", _index];
    private _diagnostic = _display getVariable ["Waldo_MG_WC_Diagnostic", controlNull];
    if (!isNull _diagnostic) then {
        _diagnostic ctrlSetText format ["B%1 // [%2] // %3", _index + 1, _identity select 2, _identity select 3];
        _diagnostic ctrlSetBackgroundColor (if ((_identity select 2) == "LIVE") then {[0.28, 0.10, 0.08, 1]} else {[0.04, 0.16, 0.14, 1]});
    };
    private _cutter = _display getVariable ["Waldo_MG_WC_CutButton", controlNull];
    if (!isNull _cutter) then {
        _cutter ctrlEnable true;
        _cutter ctrlSetText format ["ARM CUTTER // BAY %1", _index + 1];
        _cutter ctrlSetTooltip format ["Cut tested bay %1: %2, %3, %4, %5", _index + 1, _identity select 0, _identity select 1, _identity select 2, _identity select 3];
    };
    private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
    if (!isNull _status) then {_status ctrlSetText format ["[PROBE] BAY %1 // %2 CONTINUITY // %3 // COMPARE WITH ISOLATION ORDER", _index + 1, _identity select 2, _identity select 3];};
}];
_display setVariable ["Waldo_MG_WC_CutSelected", {
    params ["_display"];
    if (!(_display getVariable ["Waldo_IMG_Started", false]) || {_display getVariable ["Waldo_MG_UI_Done", false]}) exitWith {};
    private _index = _display getVariable ["Waldo_MG_WC_Selected", -1];
    if (_index < 0 || {_display getVariable ["Waldo_MG_WC_Probed", -2] != _index}) exitWith {};
    private _segments = (_display getVariable ["Waldo_MG_WC_WireSegments", []]) param [_index, [[], []]];
    private _allSegments = (_segments select 0) + (_segments select 1);
    private _middle = (count _allSegments) / 2;
    {
        if (abs (_forEachIndex - _middle) < 4) then {_x ctrlSetFade 1; _x ctrlCommit 0.18;};
    } forEach _allSegments;
    private _button = (_display getVariable ["Waldo_MG_WC_Buttons", []]) select _index;
    _button ctrlSetText format ["[X] CUT %1", _index + 1];
    _button ctrlEnable false;
    private _cutter = [_display, "RscText", [17, 8.9 + (_index * (10.2 / count (_display getVariable ["Waldo_MG_WC_WireSegments", []]))), 6, 1.5], "animated EOD cutting tool"] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _cutter ctrlSetText "< CUTTER CLOSED >";
    _cutter ctrlSetBackgroundColor [0.26, 0.28, 0.25, 0.98];
    _cutter ctrlSetTextColor [0.96, 0.78, 0.30, 1];
    if (_index == (_display getVariable ["Waldo_MG_WC_Correct", -2])) then {
        [_display, true, "[OK] COMMAND LOOM ISOLATED"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
    } else {
        [_display, false, "[X] INCORRECT LOOM SEVERED"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
    };
}];
_cutButton ctrlAddEventHandler ["ButtonClick", {
    private _display = ctrlParent (_this select 0);
    [_display] call (_display getVariable ["Waldo_MG_WC_CutSelected", {}]);
}];
_probeButton ctrlAddEventHandler ["ButtonClick", {
    private _display = ctrlParent (_this select 0);
    [_display] call (_display getVariable ["Waldo_MG_WC_ProbeSelected", {}]);
}];
[_display] call Waldo_fnc_MiniGameEquipmentBriefing;

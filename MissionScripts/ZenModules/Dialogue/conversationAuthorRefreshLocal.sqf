/*
 * Author: WaldoTheWarfighter
 * Rebuilds every Conversation Author list and selector from the selected local draft while
 * preserving bounded draft/node/line/choice selections.
 * Locality/authority: interface-local presentation only.
 * Repeat/JIP behaviour: full replacement refresh prevents stale controls after edits; no JIP state.
 * Arguments: editor DISPLAY. Return Value: BOOL.
 * Current caller: Conversation Author editor and all editor mutations.
 * Example: [_display] call Waldo_fnc_ConversationAuthorRefreshLocal;
 */
params [["_display", displayNull, [displayNull]]];
if (isNull _display) exitWith {false};
_display setVariable ["WaldoConvAuthor_Refreshing", true];
private _drafts = _display getVariable ["WaldoConvAuthor_Drafts", []];
if (count _drafts == 0) then {_drafts = [["MY_CONVERSATION", [["START", [["Hello. What would you like to know?", "", -1, -1, ""]], [["Tell me about this place.", "ABOUT", "ASK_ABOUT"], ["Goodbye.", "", "GOODBYE"]], ""], ["ABOUT", [["This is an example second part. Replace this text with your own.", "", -1, -1, ""]], [], ""]], "START"]]};
private _draftIndex = (_display getVariable ["WaldoConvAuthor_DraftIndex", 0]) max 0 min (count _drafts - 1);
_display setVariable ["WaldoConvAuthor_Drafts", _drafts];
_display setVariable ["WaldoConvAuthor_DraftIndex", _draftIndex];
private _definition = _drafts select _draftIndex;
_definition params ["_id", "_nodes", "_startNode"];
private _draftCombo = _display getVariable ["WaldoConvAuthor_DraftCombo", controlNull];
lbClear _draftCombo;
{_draftCombo lbAdd (_x param [0, format ["DRAFT %1", _forEachIndex + 1]])} forEach _drafts;
_draftCombo lbSetCurSel _draftIndex;
private _draftButtons = _display getVariable ["WaldoConvAuthor_DraftButtons", []];
if (count _draftButtons == 3) then {(_draftButtons select 2) ctrlEnable (count _drafts > 1)};
(_display getVariable ["WaldoConvAuthor_Id", controlNull]) ctrlSetText _id;
private _nodeIndex = (_display getVariable ["WaldoConvAuthor_NodeIndex", 0]) max 0 min ((count _nodes - 1) max 0);
_display setVariable ["WaldoConvAuthor_NodeIndex", _nodeIndex];
private _nodeList = _display getVariable ["WaldoConvAuthor_NodeList", controlNull];
lbClear _nodeList;
{
    private _partId = _x param [0, "PART"];
    private _choices = _x param [2, []];
    private _destinations = [];
    if (count _choices > 0) then {
        {_destinations pushBackUnique (if ((_x param [1, ""]) == "") then {"END"} else {_x param [1, ""]})} forEach _choices;
    } else {
        private _automaticNext = _x param [3, ""];
        _destinations pushBack (if (_automaticNext == "") then {"END"} else {_automaticNext});
    };
    private _startsHere = if (_partId == _startNode) then {"[BEGINS] "} else {""};
    _nodeList lbAdd format ["%1%2  ->  %3", _startsHere, _partId, _destinations joinString " / "];
} forEach _nodes;
if (count _nodes > 0) then {_nodeList lbSetCurSel _nodeIndex};
private _nodeButtons = _display getVariable ["WaldoConvAuthor_NodeButtons", []];
if (count _nodeButtons == 5) then {
    (_nodeButtons select 0) ctrlEnable (count _nodes < 128);
    (_nodeButtons select 1) ctrlEnable (count _nodes > 0 && {count _nodes < 128});
    (_nodeButtons select 2) ctrlEnable (count _nodes > 1);
    (_nodeButtons select 3) ctrlEnable (_nodeIndex > 0);
    (_nodeButtons select 4) ctrlEnable (_nodeIndex < count _nodes - 1);
};
private _nodeIds = _nodes apply {_x param [0, ""]};
private _fillDestination = {
    params ["_control", "_selected", "_allowEnd"];
    lbClear _control;
    if (_allowEnd) then {private _row = _control lbAdd "<END CONVERSATION>"; _control lbSetData [_row, ""]};
    {_control lbSetData [_control lbAdd _x, _x]} forEach _nodeIds;
    private _selection = 0;
    for "_i" from 0 to (lbSize _control - 1) do {if (_control lbData _i == _selected) exitWith {_selection = _i}};
    _control lbSetCurSel _selection;
};
[_display getVariable ["WaldoConvAuthor_StartNode", controlNull], _startNode, false] call _fillDestination;
if (count _nodes > 0) then {
    private _node = _nodes select _nodeIndex;
    _node params ["_nodeId", "_lines", "_choices", "_next"];
    private _routeDestinations = [];
    if (count _choices > 0) then {
        {_routeDestinations pushBackUnique (if ((_x param [1, ""]) == "") then {"END"} else {_x param [1, ""]})} forEach _choices;
    } else {
        _routeDestinations pushBack (if (_next == "") then {"END"} else {_next});
    };
    private _routeHelpText = if (count _choices > 0) then {
        format ["<t size='0.64'><t color='#79C7FF'>ROUTE:</t> Player answers in <t color='#FFFFFF'>%1</t> lead to <t color='#FFFFFF'>%2</t>. Select an answer in column 3 to change its route.</t>", _nodeId, _routeDestinations joinString " or "]
    } else {
        format ["<t size='0.64'><t color='#79C7FF'>ROUTE:</t> With no player answers, <t color='#FFFFFF'>%1</t> goes to <t color='#FFFFFF'>%2</t>. Use <t color='#FFFFFF'>If No Answers</t> above to change it.</t>", _nodeId, _routeDestinations joinString " or "]
    };
    (_display getVariable ["WaldoConvAuthor_RouteHelp", controlNull]) ctrlSetStructuredText parseText _routeHelpText;
    (_display getVariable ["WaldoConvAuthor_NodeId", controlNull]) ctrlSetText _nodeId;
    [_display getVariable ["WaldoConvAuthor_AutoNext", controlNull], _next, true] call _fillDestination;
    private _lineIndex = (_display getVariable ["WaldoConvAuthor_LineIndex", 0]) max 0 min ((count _lines - 1) max 0);
    _display setVariable ["WaldoConvAuthor_LineIndex", _lineIndex];
    private _lineList = _display getVariable ["WaldoConvAuthor_LineList", controlNull];
    lbClear _lineList;
    {_lineList lbAdd format ["NPC %1: %2", _forEachIndex + 1, (_x param [0, ""]) select [0, 46]]} forEach _lines;
    private _lineButtons = _display getVariable ["WaldoConvAuthor_LineButtons", []];
    if (count _lineButtons == 5) then {
        (_lineButtons select 0) ctrlEnable (count _lines < 16);
        (_lineButtons select 1) ctrlEnable (count _lines > 0 && {count _lines < 16});
        (_lineButtons select 2) ctrlEnable (count _lines > 0);
        (_lineButtons select 3) ctrlEnable (_lineIndex > 0);
        (_lineButtons select 4) ctrlEnable (_lineIndex < count _lines - 1);
    };
    if (count _lines > 0) then {
        _lineList lbSetCurSel _lineIndex;
        private _line = _lines select _lineIndex;
        (_display getVariable ["WaldoConvAuthor_LineText", controlNull]) ctrlSetText (_line param [0, ""]);
        (_display getVariable ["WaldoConvAuthor_SoundDuration", controlNull]) ctrlSetText str (_line param [2, -1]);
        (_display getVariable ["WaldoConvAuthor_TextDuration", controlNull]) ctrlSetText str (_line param [3, -1]);
        {
            _x params ["_control", "_value"];
            private _selection = 0;
            for "_i" from 0 to (lbSize _control - 1) do {if (_control lbData _i == _value) exitWith {_selection = _i}};
            _control lbSetCurSel _selection;
        } forEach [
            [_display getVariable ["WaldoConvAuthor_SoundCombo", controlNull], _line param [1, ""]],
            [_display getVariable ["WaldoConvAuthor_GestureCombo", controlNull], _line param [4, ""]]
        ];
    } else {
        (_display getVariable ["WaldoConvAuthor_LineText", controlNull]) ctrlSetText "";
    };
    private _choiceIndex = (_display getVariable ["WaldoConvAuthor_ChoiceIndex", 0]) max 0 min ((count _choices - 1) max 0);
    _display setVariable ["WaldoConvAuthor_ChoiceIndex", _choiceIndex];
    private _choiceList = _display getVariable ["WaldoConvAuthor_ChoiceList", controlNull];
    lbClear _choiceList;
    {_choiceList lbAdd format ["%1. %2  ->  %3", _forEachIndex + 1, (_x param [0, ""]) select [0, 30], if ((_x param [1, ""]) == "") then {"END"} else {_x param [1, ""]}]} forEach _choices;
    private _choiceButtons = _display getVariable ["WaldoConvAuthor_ChoiceButtons", []];
    if (count _choiceButtons == 5) then {
        (_choiceButtons select 0) ctrlEnable (count _choices < 8);
        (_choiceButtons select 1) ctrlEnable (count _choices > 0 && {count _choices < 8});
        (_choiceButtons select 2) ctrlEnable (count _choices > 0);
        (_choiceButtons select 3) ctrlEnable (_choiceIndex > 0);
        (_choiceButtons select 4) ctrlEnable (_choiceIndex < count _choices - 1);
    };
    if (count _choices > 0) then {
        _choiceList lbSetCurSel _choiceIndex;
        private _choice = _choices select _choiceIndex;
        (_display getVariable ["WaldoConvAuthor_ChoiceLabel", controlNull]) ctrlSetText (_choice param [0, ""]);
        (_display getVariable ["WaldoConvAuthor_ChoiceId", controlNull]) ctrlSetText (_choice param [2, ""]);
        [_display getVariable ["WaldoConvAuthor_ChoiceDestination", controlNull], _choice param [1, ""], true] call _fillDestination;
    } else {
        (_display getVariable ["WaldoConvAuthor_ChoiceLabel", controlNull]) ctrlSetText "";
        (_display getVariable ["WaldoConvAuthor_ChoiceId", controlNull]) ctrlSetText "";
        [_display getVariable ["WaldoConvAuthor_ChoiceDestination", controlNull], "", true] call _fillDestination;
    };
    private _hasLine = count _lines > 0;
    {(_display getVariable [_x, controlNull]) ctrlEnable _hasLine} forEach [
        "WaldoConvAuthor_LineText", "WaldoConvAuthor_SoundCombo", "WaldoConvAuthor_SoundDuration",
        "WaldoConvAuthor_TextDuration", "WaldoConvAuthor_GestureCombo"
    ];
    private _hasChoice = count _choices > 0;
    {(_display getVariable [_x, controlNull]) ctrlEnable _hasChoice} forEach [
        "WaldoConvAuthor_ChoiceLabel", "WaldoConvAuthor_ChoiceId", "WaldoConvAuthor_ChoiceDestination"
    ];
};
missionNamespace setVariable ["Waldo_Conversation_AuthorDrafts", _drafts];
_display setVariable ["WaldoConvAuthor_Refreshing", false];
true

/*
 * Author: WaldoTheWarfighter
 * Performs one bounded draft/node/line/choice add, duplicate, delete or reorder operation in the
 * Conversation Author, then refreshes the complete form.
 * Locality/authority: curator interface-local draft mutation only.
 * Repeat/JIP behaviour: deterministic mission-session draft updates; deleting a node clears inbound
 * destinations and preserves at least one node.
 * Arguments: editor DISPLAY, operation STRING. Return Value: BOOL.
 * Current caller: Conversation Author buttons.
 * Example: [_display,"NODE_ADD"] call Waldo_fnc_ConversationAuthorMutateLocal;
 */
params [["_display", displayNull, [displayNull]], ["_operation", "", [""]]];
if (isNull _display) exitWith {false};
[_display] call Waldo_fnc_ConversationAuthorSaveLocal;
private _drafts = _display getVariable ["WaldoConvAuthor_Drafts", []];
private _draftIndex = _display getVariable ["WaldoConvAuthor_DraftIndex", 0];
private _definition = _drafts select _draftIndex;
_definition params ["_id", "_nodes", "_start"];
private _nodeIndex = _display getVariable ["WaldoConvAuthor_NodeIndex", 0];
private _lineIndex = _display getVariable ["WaldoConvAuthor_LineIndex", 0];
private _choiceIndex = _display getVariable ["WaldoConvAuthor_ChoiceIndex", 0];
private _uniqueId = {
    params ["_prefix", "_existing"];
    private _counter = 1;
    private _candidate = format ["%1_%2", _prefix, _counter];
    while {_candidate in _existing} do {_counter = _counter + 1; _candidate = format ["%1_%2", _prefix, _counter]};
    _candidate
};
switch (toUpperANSI _operation) do {
    case "DRAFT_NEW": {
        private _newId = ["CONVERSATION", _drafts apply {_x param [0, ""]}] call _uniqueId;
        _drafts pushBack [_newId, [["START", [["Hello. What would you like to know?", "", -1, -1, ""]], [["Tell me about this place.", "ABOUT", "ASK_ABOUT"], ["Goodbye.", "", "GOODBYE"]], ""], ["ABOUT", [["This is an example second part. Replace this text with your own.", "", -1, -1, ""]], [], ""]], "START"];
        _draftIndex = count _drafts - 1; _nodeIndex = 0; _lineIndex = 0; _choiceIndex = 0;
    };
    case "DRAFT_DUPLICATE": {
        private _copy = parseSimpleArray str _definition;
        _copy set [0, [format ["%1_COPY", _id], _drafts apply {_x param [0, ""]}] call _uniqueId];
        _drafts pushBack _copy; _draftIndex = count _drafts - 1;
    };
    case "DRAFT_DELETE": {
        if (count _drafts > 1) then {_drafts deleteAt _draftIndex; _draftIndex = _draftIndex min (count _drafts - 1); _nodeIndex = 0; _lineIndex = 0; _choiceIndex = 0};
    };
    default {
        private _node = _nodes select _nodeIndex;
        _node params ["_nodeId", "_lines", "_choices", "_next"];
        switch (toUpperANSI _operation) do {
            case "NODE_ADD": {private _newId = ["NODE", _nodes apply {_x param [0, ""]}] call _uniqueId; _nodes pushBack [_newId, [["New line.", "", -1, -1, ""]], [], ""]; _nodeIndex = count _nodes - 1; _lineIndex = 0; _choiceIndex = 0};
            case "NODE_DUPLICATE": {private _copy = parseSimpleArray str _node; _copy set [0, [format ["%1_COPY", _nodeId], _nodes apply {_x param [0, ""]}] call _uniqueId]; _nodes pushBack _copy; _nodeIndex = count _nodes - 1};
            case "NODE_DELETE": {
                if (count _nodes > 1) then {
                    private _removed = _nodeId; _nodes deleteAt _nodeIndex; _nodeIndex = _nodeIndex min (count _nodes - 1);
                    {if ((_x param [3, ""]) == _removed) then {_x set [3, ""]}; {if ((_x param [1, ""]) == _removed) then {_x set [1, ""]}} forEach (_x param [2, []])} forEach _nodes;
                    if (_start == _removed) then {_start = (_nodes select 0) param [0, ""]};
                };
            };
            case "NODE_UP": {if (_nodeIndex > 0) then {_nodes deleteAt _nodeIndex; _nodeIndex = _nodeIndex - 1; _nodes insert [_nodeIndex, [_node]]}};
            case "NODE_DOWN": {if (_nodeIndex < count _nodes - 1) then {_nodes deleteAt _nodeIndex; _nodeIndex = _nodeIndex + 1; _nodes insert [_nodeIndex, [_node]]}};
            case "LINE_ADD": {_lines pushBack ["New line.", "", -1, -1, ""]; _lineIndex = count _lines - 1; _nodes set [_nodeIndex, [_nodeId, _lines, _choices, _next]]};
            case "LINE_DUPLICATE": {if (count _lines > 0) then {_lines insert [_lineIndex + 1, [parseSimpleArray str (_lines select _lineIndex)]]; _lineIndex = _lineIndex + 1; _nodes set [_nodeIndex, [_nodeId, _lines, _choices, _next]]}};
            case "LINE_DELETE": {if (count _lines > 0) then {_lines deleteAt _lineIndex; _lineIndex = _lineIndex min ((count _lines - 1) max 0); _nodes set [_nodeIndex, [_nodeId, _lines, _choices, _next]]}};
            case "LINE_UP": {if (_lineIndex > 0) then {private _row = _lines deleteAt _lineIndex; _lineIndex = _lineIndex - 1; _lines insert [_lineIndex, [_row]]; _nodes set [_nodeIndex, [_nodeId, _lines, _choices, _next]]}};
            case "LINE_DOWN": {if (_lineIndex < count _lines - 1) then {private _row = _lines deleteAt _lineIndex; _lineIndex = _lineIndex + 1; _lines insert [_lineIndex, [_row]]; _nodes set [_nodeIndex, [_nodeId, _lines, _choices, _next]]}};
            case "CHOICE_ADD": {private _choiceId = ["CHOICE", _choices apply {_x param [2, ""]}] call _uniqueId; _choices pushBack ["New response", "", _choiceId]; _choiceIndex = count _choices - 1; _nodes set [_nodeIndex, [_nodeId, _lines, _choices, _next]]};
            case "CHOICE_DUPLICATE": {if (count _choices > 0) then {private _copy = parseSimpleArray str (_choices select _choiceIndex); _copy set [2, [format ["%1_COPY", _copy param [2, "CHOICE"]], _choices apply {_x param [2, ""]}] call _uniqueId]; _choices insert [_choiceIndex + 1, [_copy]]; _choiceIndex = _choiceIndex + 1; _nodes set [_nodeIndex, [_nodeId, _lines, _choices, _next]]}};
            case "CHOICE_DELETE": {if (count _choices > 0) then {_choices deleteAt _choiceIndex; _choiceIndex = _choiceIndex min ((count _choices - 1) max 0); _nodes set [_nodeIndex, [_nodeId, _lines, _choices, _next]]}};
            case "CHOICE_UP": {if (_choiceIndex > 0) then {private _row = _choices deleteAt _choiceIndex; _choiceIndex = _choiceIndex - 1; _choices insert [_choiceIndex, [_row]]; _nodes set [_nodeIndex, [_nodeId, _lines, _choices, _next]]}};
            case "CHOICE_DOWN": {if (_choiceIndex < count _choices - 1) then {private _row = _choices deleteAt _choiceIndex; _choiceIndex = _choiceIndex + 1; _choices insert [_choiceIndex, [_row]]; _nodes set [_nodeIndex, [_nodeId, _lines, _choices, _next]]}};
        };
    };
};
if !((toUpperANSI _operation) find "DRAFT_" == 0) then {_drafts set [_draftIndex, [_id, _nodes, _start]]};
_display setVariable ["WaldoConvAuthor_Drafts", _drafts];
_display setVariable ["WaldoConvAuthor_DraftIndex", _draftIndex];
_display setVariable ["WaldoConvAuthor_NodeIndex", _nodeIndex];
_display setVariable ["WaldoConvAuthor_LineIndex", _lineIndex];
_display setVariable ["WaldoConvAuthor_ChoiceIndex", _choiceIndex];
missionNamespace setVariable ["Waldo_Conversation_AuthorDrafts", _drafts];
diag_log format ["[WMP CONVERSATION AUTHOR] operation=%1 draft=%2 part=%3 line=%4 answer=%5", toUpperANSI _operation, _draftIndex, _nodeIndex, _lineIndex, _choiceIndex];
[_display] call Waldo_fnc_ConversationAuthorRefreshLocal;
private _feedback = createHashMapFromArray [
    ["DRAFT_NEW", "New conversation created and selected."],
    ["DRAFT_DUPLICATE", "Conversation copied. The new conversation is selected."],
    ["DRAFT_DELETE", "Conversation deleted. The nearest remaining conversation is selected."],
    ["NODE_ADD", "New conversation part added and selected."],
    ["NODE_DUPLICATE", "Conversation part copied. The new part is selected."],
    ["NODE_DELETE", "Conversation part deleted. Routes to it were cleared."],
    ["NODE_UP", "Selected conversation part moved earlier."],
    ["NODE_DOWN", "Selected conversation part moved later."],
    ["LINE_ADD", "New line added for this NPC and selected."],
    ["LINE_DUPLICATE", "NPC line copied. The new line is selected below."],
    ["LINE_DELETE", "Highlighted NPC line deleted."],
    ["LINE_UP", "Highlighted NPC line moved earlier."],
    ["LINE_DOWN", "Highlighted NPC line moved later."],
    ["CHOICE_ADD", "New player answer added and selected."],
    ["CHOICE_DUPLICATE", "Player answer copied. The new answer is selected below."],
    ["CHOICE_DELETE", "Highlighted player answer deleted."],
    ["CHOICE_UP", "Highlighted player answer moved earlier."],
    ["CHOICE_DOWN", "Highlighted player answer moved later."]
] getOrDefault [toUpperANSI _operation, ""];
if (_feedback != "") then {
    _display setVariable ["WaldoConvAuthor_LastActionFeedback", _feedback];
    private _status = _display getVariable ["WaldoConvAuthor_Status", controlNull];
    private _theme = _display getVariable ["WaldoEcoCore_PromptTheme", [] call Waldo_fnc_UiTheme];
    if (!isNull _status) then {
        _status ctrlSetStructuredText parseText format ["<t color='%1'>DONE</t>  %2", _theme getOrDefault ["successHex", "#6CE5A8"], _feedback];
        _status ctrlCommit 0;
    };
    ["CONVERSATION", _feedback, "SUCCESS", format ["CONVERSATION_AUTHOR_%1", toUpperANSI _operation], 5]
        call Waldo_fnc_FeatureNotifyLocal;
};
true

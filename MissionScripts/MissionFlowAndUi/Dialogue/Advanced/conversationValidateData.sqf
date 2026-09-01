/*
 * Author: WaldoTheWarfighter
 * Validates the serialisable, code-free Advanced Conversation authoring schema used by mission
 * configuration and the ZEN Conversation Author. No supplied string is compiled or executed.
 * Locality/authority: pure validation on any machine; the server repeats it before registration.
 * Repeat/JIP behaviour: deterministic and side-effect free.
 * Arguments: definition ARRAY [id, nodes, startNode]. Return Value: [valid BOOL, issues ARRAY,
 * warnings ARRAY]. Current callers: ConversationCreateData and Conversation Author UI.
 * Example: [["GREETING", [["START", [["Hello.", "", -1, -1, ""]], [], ""]], "START"]] call Waldo_fnc_ConversationValidateData;
 */
params [["_definition", [], [[]]]];
private _issues = [];
private _warnings = [];
if (count _definition != 3) exitWith {[false, ["definition must contain id, nodes and startNode"], []]};
_definition params [["_id", "", [""]], ["_nodes", [], [[]]], ["_startNode", "", [""]]];
private _validId = {
    params ["_value"];
    private _upper = toUpperANSI _value;
    _value == _upper && {_value != ""} && {count _value <= 64}
        && {([_value, "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"] call BIS_fnc_filterString) == _value}
};
if !([_id] call _validId) then {_issues pushBack "conversation id must be 1-64 uppercase A-Z, 0-9 or underscore characters"};
if (count _nodes < 1 || {count _nodes > 128}) then {_issues pushBack "nodes must contain 1-128 entries"};
private _nodeIds = [];
{
    if !(_x isEqualType [] && {count _x == 4}) then {
        _issues pushBack format ["node %1 must contain id, lines, choices and automatic next", _forEachIndex];
    } else {
        _x params [["_nodeId", "", [""]], ["_lines", [], [[]]], ["_choices", [], [[]]], ["_next", "", [""]]];
        if !([_nodeId] call _validId) then {_issues pushBack format ["node %1 has an invalid id", _forEachIndex]};
        if (_nodeId in _nodeIds) then {_issues pushBack format ["duplicate node id '%1'", _nodeId]} else {_nodeIds pushBack _nodeId};
        if (count _lines > 16) then {_issues pushBack format ["node %1 has more than 16 lines", _nodeId]};
        if (count _choices > 8) then {_issues pushBack format ["node %1 has more than 8 choices", _nodeId]};
        {
            if !(_x isEqualType [] && {count _x == 5}) then {
                _issues pushBack format ["node %1 line %2 must contain text, sound, sound duration, text duration and gesture", _nodeId, _forEachIndex];
            } else {
                _x params [["_text", "", [""]], ["_sound", "", [""]], ["_soundDuration", -1, [0]], ["_duration", -1, [0]], ["_gesture", "", [""]]];
                if (_text == "" || {count _text > 500}) then {_issues pushBack format ["node %1 line %2 text must contain 1-500 characters", _nodeId, _forEachIndex]};
                if (count _sound > 128) then {_issues pushBack format ["node %1 line %2 sound id is too long", _nodeId, _forEachIndex]};
                if (_soundDuration != -1 && {_soundDuration <= 0 || {_soundDuration > 600}}) then {_issues pushBack format ["node %1 line %2 sound duration must be -1 or 0-600 seconds", _nodeId, _forEachIndex]};
                if (_duration != -1 && {_duration <= 0 || {_duration > 600}}) then {_issues pushBack format ["node %1 line %2 text duration must be -1 or 0-600 seconds", _nodeId, _forEachIndex]};
                if (count _gesture > 128) then {_issues pushBack format ["node %1 line %2 gesture is too long", _nodeId, _forEachIndex]};
            };
        } forEach _lines;
        private _choiceIds = [];
        {
            if !(_x isEqualType [] && {count _x == 3}) then {
                _issues pushBack format ["node %1 choice %2 must contain label, destination and choice id", _nodeId, _forEachIndex];
            } else {
                _x params [["_label", "", [""]], ["_destination", "", [""]], ["_choiceId", "", [""]]];
                if (_label == "" || {count _label > 160}) then {_issues pushBack format ["node %1 choice %2 label must contain 1-160 characters", _nodeId, _forEachIndex]};
                if !([_choiceId] call _validId) then {_issues pushBack format ["node %1 choice %2 has an invalid choice id", _nodeId, _forEachIndex]};
                if (_choiceId in _choiceIds) then {_issues pushBack format ["node %1 repeats choice id '%2'", _nodeId, _choiceId]} else {_choiceIds pushBack _choiceId};
                if (_destination != "" && {!([_destination] call _validId)}) then {_issues pushBack format ["node %1 choice %2 has an invalid destination id", _nodeId, _forEachIndex]};
            };
        } forEach _choices;
        if (_next != "" && {!([_next] call _validId)}) then {_issues pushBack format ["node %1 has an invalid automatic destination id", _nodeId]};
    };
} forEach _nodes;
if !(_startNode in _nodeIds) then {_issues pushBack format ["startNode '%1' does not exist", _startNode]};
{
    if (_x isEqualType [] && {count _x == 4}) then {
        _x params ["_nodeId", "_lines", "_choices", "_next"];
        if (_next != "" && {!(_next in _nodeIds)}) then {_issues pushBack format ["node %1 destination '%2' does not exist", _nodeId, _next]};
        {
            private _destination = _x param [1, ""];
            if (_destination != "" && {!(_destination in _nodeIds)}) then {_issues pushBack format ["node %1 choice destination '%2' does not exist", _nodeId, _destination]};
        } forEach _choices;
    };
} forEach _nodes;
if (count _issues == 0) then {
    private _reachable = [_startNode];
    private _cursor = 0;
    while {_cursor < count _reachable} do {
        private _current = _reachable select _cursor;
        _cursor = _cursor + 1;
        private _index = _nodes findIf {(_x param [0, ""]) == _current};
        if (_index >= 0) then {
            private _node = _nodes select _index;
            private _destinations = [_node param [3, ""]];
            {_destinations pushBack (_x param [1, ""])} forEach (_node param [2, []]);
            {if (_x != "" && {!(_x in _reachable)}) then {_reachable pushBack _x}} forEach _destinations;
        };
    };
    private _unreachable = _nodeIds select {!(_x in _reachable)};
    if (count _unreachable > 0) then {_warnings pushBack format ["unreachable nodes: %1", _unreachable joinString ", "]};
};
[count _issues == 0, _issues, _warnings]

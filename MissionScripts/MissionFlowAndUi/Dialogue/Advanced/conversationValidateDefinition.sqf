/*
 * Author: WaldoTheWarfighter
 * Validates bounds, line/choice shapes and node destinations for an Advanced Conversation definition.
 * Locality/authority: pure validation; callbacks are inspected but never executed.
 * Repeat/JIP behaviour: deterministic. Arguments: 0 definition HASHMAP. Return Value: ARRAY [valid BOOL, issues ARRAY].
 * Current caller: ConversationRegister. Example: private _result = [_definition] call Waldo_fnc_ConversationValidateDefinition;
 */
params [["_definition", createHashMap, [createHashMap]]];
private _issues = [];
private _id = _definition getOrDefault ["id", ""];
private _start = _definition getOrDefault ["startNode", ""];
private _nodes = _definition getOrDefault ["nodes", createHashMap];
if (_id == "") then {_issues pushBack "id is empty"};
if !((_definition getOrDefault ["onComplete", {}]) isEqualType {}) then {_issues pushBack "onComplete must be CODE"};
if !((_definition getOrDefault ["onCancel", {}]) isEqualType {}) then {_issues pushBack "onCancel must be CODE"};
if !(_nodes isEqualType createHashMap) then {_issues pushBack "nodes must be a HashMap"} else {
    if (count keys _nodes == 0 || {count keys _nodes > 128}) then {_issues pushBack "nodes must contain 1-128 entries"};
    if !(_start in keys _nodes) then {_issues pushBack format ["startNode '%1' does not exist", _start]};
    {
        private _nodeId = _x;
        private _node = _nodes get _nodeId;
        if !(_node isEqualType createHashMap) then {_issues pushBack format ["node %1 is not a HashMap", _nodeId]} else {
            private _lines = _node getOrDefault ["lines", []];
            private _choices = _node getOrDefault ["choices", []];
            if !((_node getOrDefault ["onEnter", {}]) isEqualType {}) then {_issues pushBack format ["node %1 onEnter must be CODE", _nodeId]};
            if (count _lines > 16) then {_issues pushBack format ["node %1 has more than 16 lines", _nodeId]};
            if (count _choices > 8) then {_issues pushBack format ["node %1 has more than 8 choices", _nodeId]};
            {
                if !(_x isEqualType createHashMap) then {_issues pushBack "line is not a HashMap"} else {
                    private _text = _x getOrDefault ["text", ""];
                    if !(_text isEqualType "" && {_text != ""} && {count _text <= 500}) then {_issues pushBack "line text must be 1-500 characters"};
                    if !((_x getOrDefault ["speaker", objNull]) isEqualType objNull) then {_issues pushBack "line speaker must be an OBJECT"};
                    if !((_x getOrDefault ["sound", ""]) isEqualType "") then {_issues pushBack "line sound must be a STRING CfgSounds id"};
                    if !((_x getOrDefault ["soundDuration", -1]) isEqualType 0) then {_issues pushBack "line soundDuration must be NUMBER"};
                    if !((_x getOrDefault ["duration", -1]) isEqualType 0) then {_issues pushBack "line duration must be NUMBER"};
                    if !((_x getOrDefault ["gesture", ""]) isEqualType "") then {_issues pushBack "line gesture must be STRING"};
                };
            } forEach _lines;
            private _choiceIds = [];
            {
                if !(_x isEqualType createHashMap) then {_issues pushBack "choice is not a HashMap"} else {
                    private _label = _x getOrDefault ["label", ""];
                    private _next = toUpperANSI (_x getOrDefault ["next", ""]);
                    private _choiceId = _x getOrDefault ["id", ""];
                    if (_label == "" || {count _label > 160}) then {_issues pushBack "choice label must be 1-160 characters"};
                    if !(_choiceId isEqualType "" && {_choiceId != ""}) then {_issues pushBack "choice id must be a non-empty STRING"};
                    if (_choiceId in _choiceIds) then {_issues pushBack format ["node %1 repeats choice id '%2'", _nodeId, _choiceId]} else {_choiceIds pushBack _choiceId};
                    if !((_x getOrDefault ["condition", {true}]) isEqualType {}) then {_issues pushBack "choice condition must be CODE"};
                    if !((_x getOrDefault ["onSelect", {}]) isEqualType {}) then {_issues pushBack "choice onSelect must be CODE"};
                    if (_next != "" && {!(_next in keys _nodes)}) then {_issues pushBack format ["choice destination '%1' does not exist", _next]};
                };
            } forEach _choices;
            private _next = toUpperANSI (_node getOrDefault ["next", ""]);
            if (_next != "" && {!(_next in keys _nodes)}) then {_issues pushBack format ["node destination '%1' does not exist", _next]};
        };
    } forEach keys _nodes;
};
[count _issues == 0, _issues]

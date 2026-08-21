/*
 * Author: WaldoTheWarfighter
 * Converts a beginner-readable node array into an Advanced Conversation definition and registers it.
 * Locality/authority: server-only authoring helper; CODE values stay on the server.
 * Repeat/JIP behaviour: replacing the same ID affects future sessions, not a running session copy.
 * Arguments: id STRING, nodes ARRAY, start node STRING (default first), onComplete CODE, onCancel CODE.
 * Return Value: BOOL. Current caller: mission-maker Eden init, triggers or scripts.
 * Example: ["GREETING", [["START", ["Hello."], [["Goodbye", ""]]]]] call Waldo_fnc_ConversationCreate;
 */
params [["_id", "", [""]], ["_rows", [], [[]]], ["_startNode", "", [""]], ["_onComplete", {}, [{}]], ["_onCancel", {}, [{}]]];
if (!isServer || {_id == ""} || {count _rows == 0}) exitWith {false};
private _nodes = createHashMap;
{
    _x params [["_nodeId", "", [""]], ["_lineRows", [], [[]]], ["_choiceRows", [], [[]]], ["_onEnter", {}, [{}]], ["_next", "", [""]]];
    private _lines = [];
    {
        if (_x isEqualType "") then {
            _lines pushBack (createHashMapFromArray [["text", _x]]);
        } else {
            if (_x isEqualType []) then {
                _lines pushBack (createHashMapFromArray [
                    ["speaker", _x param [0, objNull, [objNull]]], ["text", _x param [1, "", [""]]],
                    ["sound", _x param [2, "", [""]]], ["soundDuration", _x param [3, -1, [0]]],
                    ["duration", _x param [4, -1, [0]]], ["gesture", _x param [5, "", [""]]]
                ]);
            };
        };
    } forEach _lineRows;
    private _choices = [];
    {
        _choices pushBack (createHashMapFromArray [
            ["label", _x param [0, "", [""]]], ["next", _x param [1, "", [""]]],
            ["condition", _x param [2, {true}, [{}]]], ["onSelect", _x param [3, {}, [{}]]],
            ["id", _x param [4, format ["CHOICE_%1", _forEachIndex], [""]]]
        ]);
    } forEach _choiceRows;
    _nodes set [toUpperANSI _nodeId, createHashMapFromArray [["lines", _lines], ["choices", _choices], ["onEnter", _onEnter], ["next", toUpperANSI _next]]];
} forEach _rows;
if (_startNode == "") then {_startNode = toUpperANSI ((_rows select 0) param [0, ""])};
[createHashMapFromArray [["id", toUpperANSI _id], ["startNode", toUpperANSI _startNode], ["nodes", _nodes], ["onComplete", _onComplete], ["onCancel", _onCancel]]] call Waldo_fnc_ConversationRegister

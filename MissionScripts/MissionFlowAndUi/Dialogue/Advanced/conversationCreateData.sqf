/*
 * Author: WaldoTheWarfighter
 * Converts one validated, serialisable conversation definition into the existing Advanced
 * Conversation runtime format. The schema contains no CODE or object references and is safe for
 * mission configuration and authenticated ZEN submissions.
 * Locality/authority: server-only registration. Repeat/JIP behaviour: replacing an ID affects
 * future sessions and republishes the catalogue; running sessions keep their retained definition.
 * Arguments: definition ARRAY [id, nodes, startNode]. Return Value: BOOL.
 * Current callers: configured conversation loader and ZEN author server.
 * Example: [["GREETING", [["START", [["Hello.", "", -1, -1, ""]], [], ""]], "START"]] call Waldo_fnc_ConversationCreateData;
 */
params [["_definition", [], [[]]]];
if (!isServer) exitWith {false};
private _validation = [_definition] call Waldo_fnc_ConversationValidateData;
if !(_validation select 0) exitWith {
    diag_log format ["[WMP CONVERSATION] Safe definition rejected: %1", (_validation select 1) joinString "; "];
    false
};
_definition params ["_id", "_nodes", "_startNode"];
private _rows = _nodes apply {
    _x params ["_nodeId", "_lines", "_choices", "_next"];
    private _runtimeLines = _lines apply {
        _x params ["_text", "_sound", "_soundDuration", "_duration", "_gesture"];
        [objNull, _text, _sound, _soundDuration, _duration, _gesture]
    };
    private _runtimeChoices = _choices apply {
        _x params ["_label", "_destination", "_choiceId"];
        [_label, _destination, {true}, {}, _choiceId]
    };
    [_nodeId, _runtimeLines, _runtimeChoices, {}, _next]
};
private _ok = [_id, _rows, _startNode] call Waldo_fnc_ConversationCreate;
if (_ok) then {
    private _safeDefinitions = missionNamespace getVariable ["Waldo_Conversation_SafeDefinitions", createHashMap];
    _safeDefinitions set [_id, +_definition];
    missionNamespace setVariable ["Waldo_Conversation_SafeDefinitions", _safeDefinitions];
};
_ok

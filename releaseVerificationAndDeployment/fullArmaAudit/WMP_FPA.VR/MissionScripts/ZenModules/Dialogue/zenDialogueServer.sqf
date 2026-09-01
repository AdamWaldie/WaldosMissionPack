/*
 * Author: WaldoTheWarfighter
 * Authenticates ZEN dialogue operations and routes them through the normal public APIs.
 * Locality/authority: server-only; requester must own the remote call and an assigned curator logic.
 * Repeat/JIP behaviour: public APIs provide replacement, locking and snapshot semantics.
 * Arguments: operation STRING, target OBJECT, values ARRAY, requester OBJECT. Return Value: BOOL.
 * Current callers: four dialogue/conversation ZEN handlers.
 * Example: ZEN remote execution only.
 */
params [["_operation", "", [""]], ["_target", objNull, [objNull]], ["_values", [], [[]]], ["_requester", objNull, [objNull]]];
if (!isServer || {isNull _requester}) exitWith {false};
if (remoteExecutedOwner > 0 && {owner _requester != remoteExecutedOwner || {isNull getAssignedCuratorLogic _requester}}) exitWith {false};
private _operationKey = toUpperANSI _operation;
if (isNull _target || {!(_target isKindOf "CAManBase")}) exitWith {false};
private _ok = false;
switch (_operationKey) do {
    case "SIMPLE_ARCHETYPE": {
        _values params [["_id", "", [""]], ["_group", false, [true]], ["_once", false, [true]]];
        private _targets = if (_group) then {group _target} else {_target};
        _ok = [_targets, _id, "", {}, _once] call Waldo_fnc_SimpleDialogue;
    };
    case "SIMPLE_LINES": {
        _values params [["_text", "", [""]], ["_group", false, [true]], ["_once", false, [true]]];
        private _lines = (_text splitString "|") select {_x != ""};
        private _targets = if (_group) then {group _target} else {_target};
        _ok = [_targets, _lines, {}, _once] call Waldo_fnc_SimpleDialogue;
    };
    case "CLEAR": {
        private _targets = if (_values param [0, false]) then {group _target} else {_target};
        private _a = [_targets] call Waldo_fnc_SimpleDialogueClear;
        private _b = [_targets] call Waldo_fnc_ConversationClear;
        _ok = _a || _b;
    };
    case "ADVANCED_ASSIGN": {
        if (_values findIf {!(_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""})} >= 0) exitWith {};
        private _payload = createHashMapFromArray _values;
        private _id = _payload getOrDefault ["conversationId", ""];
        private _group = _payload getOrDefault ["applyToGroup", false];
        private _once = _payload getOrDefault ["removeAfterUse", false];
        if (_id isEqualType "" && {_group isEqualType true} && {_once isEqualType true}) then {
            _ok = [if (_group) then {group _target} else {_target}, _id, _once] call Waldo_fnc_ConversationAssign;
        };
    };
};
private _message = if (_ok) then {"Dialogue operation completed."} else {"Dialogue operation was rejected; check the target and registered IDs."};
["DIALOGUE", _message, if (_ok) then {"SUCCESS"} else {"WARNING"}, "DIALOGUE_ZEN", 6] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _requester];
_ok

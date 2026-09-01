/*
 * Author: WaldoTheWarfighter
 * Authenticates and applies one code-free Conversation Author submission. Named values are parsed
 * on the server, the complete definition and target are revalidated, and no submitted string is
 * compiled or executed.
 * Locality/authority: server-only remote endpoint for an assigned curator-owned player.
 * Repeat/JIP behaviour: explicit replacement is required for an existing ID; registration updates
 * the catalogue revision and normal assignment publishes the complete action snapshot.
 * Arguments: named value rows ARRAY, requester OBJECT. Return Value: BOOL.
 * Current caller: ZEN Conversation Author editor.
 * Example: ZEN authenticated remote execution only.
 */
params [["_rows", [], [[]]], ["_requester", objNull, [objNull]]];
if (!isServer || {isNull _requester}) exitWith {false};
if (remoteExecutedOwner <= 0 || {owner _requester != remoteExecutedOwner} || {isNull getAssignedCuratorLogic _requester}) exitWith {false};
if (_rows findIf {!(_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""})} >= 0) exitWith {false};
private _payload = createHashMapFromArray _rows;
private _requestId = _payload getOrDefault ["requestId", ""];
private _definition = _payload getOrDefault ["definition", []];
private _modeValue = _payload getOrDefault ["assignmentMode", "NONE"];
private _target = _payload getOrDefault ["target", objNull];
private _removeAfterUse = _payload getOrDefault ["removeAfterUse", false];
private _replace = _payload getOrDefault ["replaceExisting", false];
if !(
    _requestId isEqualType "" && {_requestId != ""}
    && {_definition isEqualType []}
    && {_modeValue isEqualType ""}
    && {_target isEqualType objNull}
    && {_removeAfterUse isEqualType true}
    && {_replace isEqualType true}
) exitWith {false};
private _mode = toUpperANSI _modeValue;
private _ok = false;
private _message = "Conversation definition was rejected.";
private _validation = [_definition] call Waldo_fnc_ConversationValidateData;
if !(_validation select 0) then {
    _message = format ["Definition rejected: %1", (_validation select 1) joinString "; "];
} else {
    private _id = _definition param [0, ""];
    private _definitions = missionNamespace getVariable ["Waldo_Conversation_Definitions", createHashMap];
    if (_id in keys _definitions && {!_replace}) then {
        _message = format ["Conversation %1 already exists. Enable Replace existing to update it.", _id];
    } else {
        private _targetValid = _mode == "NONE" || {!isNull _target && {_target isKindOf "CAManBase"} && {alive _target}};
        if !(_mode in ["NONE", "TARGET", "GROUP"] && {_targetValid}) then {
            _message = "Direct assignment requires a living NPC target.";
        } else {
            _ok = [_definition] call Waldo_fnc_ConversationCreateData;
            if (_ok && {_mode != "NONE"}) then {
                private _targets = if (_mode == "GROUP") then {group _target} else {_target};
                _ok = [_targets, _id, _removeAfterUse] call Waldo_fnc_ConversationAssign;
            };
            _message = if (_ok) then {
                if (_mode == "NONE") then {format ["Conversation %1 registered for assignment.", _id]} else {format ["Conversation %1 registered and assigned.", _id]}
            } else {"Conversation registration or assignment failed server validation."};
        };
    };
};
[_requestId, _ok, _message, _validation param [2, []]] remoteExecCall ["Waldo_fnc_ZenConversationAuthorResultLocal", owner _requester];
_ok

/*
 * Author: WaldoTheWarfighter
 * Authenticates and enqueues one seated MiniGames request, then drains that table's queue in order.
 * It replaces all public per-player request variables and the permanent authority scanner.
 *
 * Locality/authority: Server only. remoteExecutedOwner and actor ownership are checked before enqueue.
 * Rule processors remain server-authoritative. Acknowledgements and refresh signals are owner-targeted.
 * Repeat/JIP: Duplicate tokens are rejected. Queue workers exist only while a table has pending work.
 * Arguments: Envelope [1, table Object, token String, phaseEpoch Number, operation String, payload Array, actor Object].
 * Return Value: Nothing; result is sent to the actor's current owner.
 * Current callers: Waldo_MG_fnc_submitRequestLocal through remoteExecCall.
 * Example: [1, _table, _token, 3, "VOTE", _legacyPayload, player] remoteExecCall ["Waldo_fnc_MiniGamesRequestServer", 2];
 */

params [
    ["_version", -1, [0]],
    ["_table", objNull, [objNull]],
    ["_token", "", [""]],
    ["_phaseEpoch", -1, [0]],
    ["_operation", "", [""]],
    ["_payload", [], [[]]],
    ["_actor", objNull, [objNull]]
];
if (!isServer) exitWith {};
call Waldo_fnc_MiniGamesEnsureRuntime;

private _reply = {
    params ["_accepted", "_reason", ["_revision", -1]];
    if (!isNull _actor && {_token != ""}) then {
        [_token, _accepted, _reason, _revision] remoteExecCall ["Waldo_fnc_MiniGamesRequestResultLocal", owner _actor];
    };
};
if (_version != 1) exitWith {[false, "Unsupported MiniGames request protocol."] call _reply};
if (isNull _actor || {isNull _table} || {_token == ""}) exitWith {[false, "Malformed MiniGames request."] call _reply};
if (remoteExecutedOwner > 0 && {owner _actor != remoteExecutedOwner}) exitWith {
    diag_log format ["[WMP MINIGAMES] Rejected forged actor owner=%1 remoteOwner=%2 operation=%3", owner _actor, remoteExecutedOwner, _operation];
    [false, "MiniGames request owner validation failed."] call _reply;
};
if !(_table getVariable ["Waldo_MG_IsPartyTable", false]) exitWith {[false, "That table is not registered."] call _reply};

private _registry = missionNamespace getVariable ["Waldo_MG_ServerRegistry", createHashMap];
private _tableId = _table getVariable ["Waldo_MG_TableId", ""];
if !(_tableId in _registry) exitWith {[false, "That table is not in the authoritative registry."] call _reply};
private _entry = _registry get _tableId;
private _tokens = +(_entry getOrDefault ["tokens", []]);
if (_token in _tokens) exitWith {[false, "Duplicate MiniGames request.", _table getVariable ["Waldo_MG_TableRevision", -1]] call _reply};
if ((count _payload) == 0 || {(_payload param [0, ""]) != _token} || {(_payload param [1, ""]) != netId _table}) exitWith {[false, "MiniGames request envelope did not match its payload."] call _reply};

private _operations = ["JOIN","LEAVE","VOTE","READY","BATTLESHIP","WHOSWHO","SHOTGUN","CHECKERS_MOVE","CHECKERS_RESET","RPS","BLACKJACK","CHESS_MOVE","CHESS_ACTION","POKER","DRAWPOKER","LIARSDICE","CONNECTFOUR","UNO"];
if !(_operation in _operations) exitWith {[false, "Unknown MiniGames operation."] call _reply};
private _phaseVariable = switch (_operation) do {
    case "BATTLESHIP": {"Waldo_MG_BattleshipRevision"};
    case "WHOSWHO": {"Waldo_MG_WhosWhoRevision"};
    case "SHOTGUN": {"Waldo_MG_ShotgunRevision"};
    case "CHECKERS_MOVE";
    case "CHECKERS_RESET": {"Waldo_MG_CheckersRevision"};
    case "RPS": {"Waldo_MG_RPSEpoch"};
    case "BLACKJACK": {"Waldo_MG_BlackjackEpoch"};
    case "CHESS_MOVE";
    case "CHESS_ACTION": {"Waldo_MG_ChessRevision"};
    case "POKER": {"Waldo_MG_PokerRevision"};
    case "DRAWPOKER": {"Waldo_MG_DrawPokerEpoch"};
    case "LIARSDICE": {"Waldo_MG_LiarsDiceEpoch"};
    case "CONNECTFOUR": {"Waldo_MG_ConnectFourEpoch"};
    case "UNO": {"Waldo_MG_UNORevision"};
    default {"Waldo_MG_TableRevision"};
};
private _currentPhaseEpoch = _table getVariable [_phaseVariable, -1];
if (_phaseEpoch != _currentPhaseEpoch) exitWith {
    [_table, _table getVariable ["Waldo_MG_TableRevision", -1]] remoteExecCall ["Waldo_fnc_MiniGamesStateChangedLocal", owner _actor];
    [false, "The table changed before that action arrived. Current state has been refreshed.", _table getVariable ["Waldo_MG_TableRevision", -1]] call _reply;
};
if (!alive _actor) exitWith {[false, "You must be alive to use the party table."] call _reply};
private _range = _table getVariable ["Waldo_MG_TableActionRange", Waldo_MG_CFG_ACTION_RANGE];
if (_operation == "JOIN") then {
    if ((_actor distance _table) > (_range max Waldo_MG_CFG_REQUEST_RANGE)) exitWith {[false, "Move closer to the party table."] call _reply};
} else {
    if ((_actor getVariable ["Waldo_MG_SeatedTable", objNull]) != _table) exitWith {[false, "Your table seat is stale."] call _reply};
    if ((_actor distance _table) > Waldo_MG_CFG_REQUEST_RANGE) exitWith {[false, "Your party-table position is stale."] call _reply};
};

_tokens pushBack _token;
while {(count _tokens) > 256} do {_tokens deleteAt 0;};
_entry set ["tokens", _tokens];
private _queue = +(_entry getOrDefault ["queue", []]);
_queue pushBack [_operation, _actor, +_payload, _phaseEpoch];
_entry set ["queue", _queue];
_registry set [_tableId, _entry];
missionNamespace setVariable ["Waldo_MG_ServerRegistry", _registry];

if !(_entry getOrDefault ["draining", false]) then {
    _entry set ["draining", true];
    _registry set [_tableId, _entry];
    missionNamespace setVariable ["Waldo_MG_ServerRegistry", _registry];
    [_tableId] spawn {
        params ["_queuedTableId"];
        private _activeRegistry = missionNamespace getVariable ["Waldo_MG_ServerRegistry", createHashMap];
        while {
            _queuedTableId in _activeRegistry
            && {(count ((_activeRegistry get _queuedTableId) getOrDefault ["queue", []])) > 0}
        } do {
            private _activeEntry = _activeRegistry get _queuedTableId;
            private _activeQueue = +(_activeEntry getOrDefault ["queue", []]);
            private _request = _activeQueue deleteAt 0;
            _activeEntry set ["queue", _activeQueue];
            _activeRegistry set [_queuedTableId, _activeEntry];
            missionNamespace setVariable ["Waldo_MG_ServerRegistry", _activeRegistry];
            _request params ["_queuedOperation", "_queuedActor", "_legacyPayload", "_queuedPhaseEpoch"];
            switch (_queuedOperation) do {
                case "JOIN": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processJoinRequestServer;};
                case "LEAVE": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processLeaveRequestServer;};
                case "VOTE": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processVoteRequestServer;};
                case "READY": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processReadyRequestServer;};
                case "BATTLESHIP": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processBattleshipActionRequestServer;};
                case "WHOSWHO": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processWhosWhoActionRequestServer;};
                case "SHOTGUN": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processShotgunActionRequestServer;};
                case "CHECKERS_MOVE": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processCheckersMoveRequestServer;};
                case "CHECKERS_RESET": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processCheckersResetRequestServer;};
                case "RPS": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processRPSActionRequestServer;};
                case "BLACKJACK": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processBlackjackActionRequestServer;};
                case "CHESS_MOVE": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processChessMoveRequestServer;};
                case "CHESS_ACTION": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processChessActionRequestServer;};
                case "POKER": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processPokerActionRequestServer;};
                case "DRAWPOKER": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processDrawPokerActionRequestServer;};
                case "LIARSDICE": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processLiarsDiceActionRequestServer;};
                case "CONNECTFOUR": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processConnectFourActionRequestServer;};
                case "UNO": {[_queuedActor, _legacyPayload] call Waldo_MG_fnc_processUNOActionRequestServer;};
            };
            private _activeTable = _activeEntry getOrDefault ["table", objNull];
            if (!isNull _activeTable) then {
                [_activeTable] call Waldo_MG_fnc_reconcileOneTableServer;
                [_activeTable] call Waldo_MG_fnc_publishTableChangeServer;
                [_activeTable] call Waldo_MG_fnc_scheduleTimedProgressServer;
            };
            _activeRegistry = missionNamespace getVariable ["Waldo_MG_ServerRegistry", createHashMap];
        };
        _activeRegistry = missionNamespace getVariable ["Waldo_MG_ServerRegistry", createHashMap];
        if (_queuedTableId in _activeRegistry) then {
            private _finishedEntry = _activeRegistry get _queuedTableId;
            _finishedEntry set ["draining", false];
            _activeRegistry set [_queuedTableId, _finishedEntry];
            missionNamespace setVariable ["Waldo_MG_ServerRegistry", _activeRegistry];
        };
    };
};

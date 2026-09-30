/*
 * Author: WaldoTheWarfighter
 * Reports owner acceptance instead of treating successful network dispatch as success.
 * Locality/authority: server authenticates dispatch; the current owner executes group commands.
 * Repeat/JIP: request tokens are consumed once; no stale order is replayed for JIP.
 * Arguments: 0: token <STRING>; 1: accepted <BOOL>; 2: timed out <BOOL>, default false.
 * 3: reply owner <NUMBER>, default -1; owner replies supply clientOwner, server callbacks omit it.
 * 4: failure reason <STRING>, default empty; supplied by the executing owner.
 * Return Value: Nothing.
 * Current callers: AIPassOrderLocal and server timeout.
 * Example: [_token, true, false, clientOwner] remoteExecCall ["Waldo_fnc_CortexOrderResult", 2];
 */
params [["_token", "", [""]], ["_accepted", false, [true]], ["_timeout", false, [true]], ["_replyOwner",-1,[0]], ["_reason","",[""]]];
if (!isServer) exitWith {};
private _pending = missionNamespace getVariable ["Waldo_AIPass_OrderPending", createHashMap];
private _request = _pending getOrDefault [_token, []];
if (_request isEqualTo []) exitWith {};
_request params ["_requestOwner", "_group", "_expectedOwner", "_order"];
private _ownerReply = remoteExecutedOwner > 0 || {_replyOwner > 0};
if (_ownerReply && {_timeout || {([_replyOwner,_expectedOwner] call Waldo_fnc_HeadlessResolveSender) < 0} || {_expectedOwner != groupOwner _group}}) exitWith {};
_pending deleteAt _token;
private _message = if (!_accepted && {_reason != ""} && {!_timeout}) then {_reason} else {if (_timeout) then {"The AI owner did not confirm the order. It may have changed owner; inspect its state before retrying."} else {
    format ["%1: %2.", _order, ["refused by the current owner; check group, target and feature settings", "accepted by the current owner"] select _accepted]
}};
diag_log format ["[WMP ZEN SERVER] action=AI_ORDER owner=%1 order=%2 accepted=%3 timeout=%4", _requestOwner, _order, _accepted, _timeout];
if (_requestOwner > 2 || {hasInterface}) then {
    ["AI ORDERS", _message, ["ERROR", "SUCCESS"] select (_accepted && {!_timeout}), "AI_ORDERS", 7] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _requestOwner];
};

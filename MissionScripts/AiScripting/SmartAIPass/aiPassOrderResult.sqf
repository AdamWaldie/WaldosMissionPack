/*
 * Author: WaldoTheWarfighter
 * Reports owner acceptance instead of treating successful network dispatch as success.
 * Locality/authority: server authenticates dispatch; the current owner executes group commands.
 * Repeat/JIP: request tokens are consumed once; no stale order is replayed for JIP.
 * Arguments: 0: token <STRING>; 1: accepted <BOOL>; 2: timed out <BOOL>, default false.
 * Return Value: Nothing.
 * Current callers: AIPassOrderLocal and server timeout.
 * Example: [_token, true] remoteExecCall ["Waldo_fnc_AIPassOrderResult", 2];
 */
params [["_token", "", [""]], ["_accepted", false, [true]], ["_timeout", false, [true]]];
if (!isServer) exitWith {};
private _pending = missionNamespace getVariable ["Waldo_AIPass_OrderPending", createHashMap];
private _request = _pending getOrDefault [_token, []];
if (_request isEqualTo []) exitWith {};
_request params ["_requestOwner", "_group", "_expectedOwner", "_order"];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != _expectedOwner || {remoteExecutedOwner != groupOwner _group} || {_timeout}}) exitWith {};
_pending deleteAt _token;
private _message = if (_timeout) then {"The AI owner did not confirm the order. It may have changed owner; inspect its state before retrying."} else {
    format ["%1: %2.", _order, ["refused by the current owner; check group, target and feature settings", "accepted by the current owner"] select _accepted]
};
diag_log format ["[WMP ZEN SERVER] action=AI_ORDER owner=%1 order=%2 accepted=%3 timeout=%4", _requestOwner, _order, _accepted, _timeout];
if (_requestOwner > 2 || {hasInterface}) then {
    ["AI ORDERS", _message, ["ERROR", "SUCCESS"] select (_accepted && {!_timeout}), "AI_ORDERS", 7] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _requestOwner];
};

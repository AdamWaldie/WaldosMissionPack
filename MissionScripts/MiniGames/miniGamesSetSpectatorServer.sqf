/*
 * Author: WaldoTheWarfighter
 * Subscribe or unsubscribe one interface player from a live MiniGames table.
 *
 * Locality / Authority:
 * Server only. The server updates its private table-recipient registry. Enabling sends one targeted
 * current-state snapshot; disabling only removes that player from future game-state recipients.
 *
 * Repeat / JIP Behaviour:
 * Repeat-safe through pushBackUnique/subtraction. A JIP player is not subscribed until they choose
 * Spectate Game, so game state is never retained in the JIP queue.
 *
 * Arguments:
 * 0: _table <OBJECT> - registered table
 * 1: _actor <OBJECT> - player requesting the spectator view
 * 2: _enabled <BOOLEAN> - true to subscribe and open; false to unsubscribe
 *
 * Return Value:
 * <BOOLEAN> - true when the registered table entry was updated
 *
 * Current Callers:
 * Waldo_MG_fnc_openSpectatorLocal and Waldo_MG_fnc_exitSpectatorLocal.
 *
 * Example:
 * [_table, player, true] remoteExecCall ["Waldo_fnc_MiniGamesSetSpectatorServer", 2];
 */

params [
    ["_table", objNull, [objNull]],
    ["_actor", objNull, [objNull]],
    ["_enabled", false, [false]]
];
if (!isServer || {isNull _table} || {isNull _actor}) exitWith {false};
call Waldo_fnc_MiniGamesEnsureRuntime;

private _registry = missionNamespace getVariable ["Waldo_MG_ServerRegistry", createHashMap];
private _tableId = _table getVariable ["Waldo_MG_TableId", netId _table];
if !(_tableId in _registry) exitWith {false};

private _entry = _registry get _tableId;
private _spectators = +(_entry getOrDefault ["spectators", []]);
_spectators = _spectators select {!isNull _x && {isPlayer _x}};
if (_enabled) then {
    _spectators pushBackUnique _actor;
} else {
    _spectators = _spectators - [_actor];
};
_entry set ["spectators", _spectators];
_registry set [_tableId, _entry];
missionNamespace setVariable ["Waldo_MG_ServerRegistry", _registry];

if (_enabled) then {
    [_table, _actor, true] call Waldo_MG_fnc_sendPublicTableSnapshotServer;
};
true

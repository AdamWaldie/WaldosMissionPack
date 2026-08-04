/*
 * Author: WaldoTheWarfighter
 * Validates player persistence requests and performs all INIDBI2 player reads/writes on the server.
 *
 * Arguments:
 * 0: operation <STRING> - LOAD_PLAYER or SAVE_PLAYER
 * 1: payload <ARRAY> - player-state payload for SAVE_PLAYER
 *
 * Return Value:
 * Boolean - true when the request was handled
 *
 * Example:
 * ["SAVE_PLAYER", _state] remoteExecCall ["Waldo_fnc_PersistenceServerHandle", 2];
 */

params [
    ["_operation", "", [""]],
    ["_payload", [], [[]]]
];
if !(isServer) exitWith {false};
if !(missionNamespace getVariable ["Waldo_Persistence_Active", false]) exitWith {false};

private _requestOwner = remoteExecutedOwner;
private _playerIndex = allPlayers findIf {owner _x == _requestOwner};
if (_playerIndex < 0) exitWith {
    diag_log format ["[WMP PERSISTENCE] Rejected %1 request from unknown owner %2.", _operation, _requestOwner];
    false
};

private _requestPlayer = allPlayers select _playerIndex;
private _uid = getPlayerUID _requestPlayer;
if (_uid == "") exitWith {false};

private _databaseName = missionNamespace getVariable ["Waldo_Persistence_DatabaseName", "WaldosMissionPack"];
private _safeDatabaseName = [_databaseName, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
if (_safeDatabaseName == "") then {_safeDatabaseName = "WaldosMissionPack"};
private _scopeMode = toUpper (missionNamespace getVariable ["Waldo_Persistence_Scope", "MISSION"]);
private _scopeSource = if (_scopeMode == "CAMPAIGN") then {_safeDatabaseName} else {format ["%1_%2_%3", _safeDatabaseName, missionName, worldName]};
private _scopeKey = [_scopeSource, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
if (_scopeKey == "") then {_scopeKey = format ["WaldosMissionPack_%1", worldName]};
private _fileName = format ["%1_PLAYER_%2", _scopeKey, _uid];
private _db = ["new", _fileName] call OO_INIDBI;

switch (toUpperANSI _operation) do {
    case "LOAD_PLAYER": {
        private _stored = ["read", ["WMP", "PlayerState", []]] call _db;
        if (count _stored >= 4 && {(_stored select 0) == "WMP_PLAYER_STATE"} && {(_stored select 1) == _uid} && {(_stored select 2) == _scopeKey}) then {
            [_stored select 3] remoteExecCall ["Waldo_fnc_PersistenceClientApply", _requestOwner];
        } else {
            if (count _stored > 0) then {diag_log format ["[WMP PERSISTENCE] Rejected stored player state whose identity did not match UID/scope %1/%2.", _uid, _scopeKey]};
        };
        true
    };
    case "SAVE_PLAYER": {
        if (count _payload < 6 || {(_payload select 0) != 1}) exitWith {false};
        ["write", ["WMP", "Schema", 1]] call _db;
        ["write", ["WMP", "PlayerName", name _requestPlayer]] call _db;
        ["write", ["WMP", "PlayerState", ["WMP_PLAYER_STATE", _uid, _scopeKey, _payload]]] call _db;
        true
    };
    default {
        diag_log format ["[WMP PERSISTENCE] Rejected unknown operation '%1'.", _operation];
        false
    };
}

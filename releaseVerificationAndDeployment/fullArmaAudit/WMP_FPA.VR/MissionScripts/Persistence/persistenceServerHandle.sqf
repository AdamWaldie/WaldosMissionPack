/*
 * Author: Waldo
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
private _fileName = format ["%1_PLAYER_%2", _safeDatabaseName, _uid];
private _db = ["new", _fileName] call OO_INIDBI;

switch (toUpperANSI _operation) do {
    case "LOAD_PLAYER": {
        private _state = ["read", ["WMP", "PlayerState", []]] call _db;
        if (count _state > 0) then {
            [_state] remoteExecCall ["Waldo_fnc_PersistenceClientApply", _requestOwner];
        };
        true
    };
    case "SAVE_PLAYER": {
        if (count _payload < 6 || {(_payload select 0) != 1}) exitWith {false};
        ["write", ["WMP", "Schema", 1]] call _db;
        ["write", ["WMP", "PlayerName", name _requestPlayer]] call _db;
        ["write", ["WMP", "PlayerState", _payload]] call _db;
        true
    };
    default {
        diag_log format ["[WMP PERSISTENCE] Rejected unknown operation '%1'.", _operation];
        false
    };
}

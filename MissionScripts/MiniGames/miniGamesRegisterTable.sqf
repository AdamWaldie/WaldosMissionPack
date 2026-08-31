/*
 * Author: WaldoTheWarfighter
 * Explicitly registers one object as a seated MiniGames table and applies optional presentation,
 * game-catalogue, seat-geometry, and interaction-range settings. Registration is the only activation
 * path. Invalid keys, games, objects, or geometry are rejected and logged.
 *
 * Locality/authority: Safe from an object init on every machine. The server alone creates authority
 * state and publishes compact metadata; interface clients install local actions and presentation.
 * Repeat/JIP: Equivalent calls are repeat-safe. JIP is replayed by MiniGamesInitPlayerLocal.
 *
 * Arguments:
 * 0: Object - table object.
 * 1: HashMap - optional settings; defaults to current four-seat geometry and all games.
 * Return Value: Boolean - true when this machine accepted the registration.
 * Current callers: Mission/composition object init fields and MiniGamesRegisterTableLocal replay.
 * Example: [this, createHashMapFromArray [["games", ["chess", "checkers"]]]] call Waldo_fnc_MiniGamesRegisterTable;
 */

params [
    ["_table", objNull, [objNull]],
    ["_options", createHashMap, [createHashMap]]
];

private _reject = {
    params ["_reason"];
    diag_log format ["[WMP MINIGAMES] Table registration rejected: %1 table=%2", _reason, _table];
    false
};
if (isNull _table) exitWith {["object is null"] call _reject};
if ((typeName _options) != "HASHMAP") exitWith {["options must be a HashMap"] call _reject};

private _allowedKeys = ["displayName", "games", "seatOffsets", "seatExitOffsets", "seatDirections", "actionRange"];
private _unknownKeys = (keys _options) select {!(_x in _allowedKeys)};
if ((count _unknownKeys) > 0) exitWith {[format ["unknown option key(s): %1", _unknownKeys]] call _reject};

private _displayName = _options getOrDefault ["displayName", "Party Table"];
private _games = _options getOrDefault ["games", []];
private _seatOffsets = _options getOrDefault ["seatOffsets", [[0,-1.05,0],[0,1.05,0],[-1.35,0,0],[1.35,0,0]]];
private _seatExitOffsets = _options getOrDefault ["seatExitOffsets", [[0,-1.85,0],[0,1.85,0],[-2.05,0,0],[2.05,0,0]]];
private _seatDirections = _options getOrDefault ["seatDirections", [0,180,90,270]];
private _actionRange = _options getOrDefault ["actionRange", 4.5];

if ((typeName _displayName) != "STRING" || {_displayName == ""}) exitWith {["displayName must be a non-empty string"] call _reject};
if ((typeName _games) != "ARRAY") exitWith {["games must be an array"] call _reject};
_games = +_games;
private _catalogue = ["battleship","whoswho","shotgun","blackjack","poker","drawpoker","liarsdice","chess","checkers","connectfour","rps","uno"];
if ((count _games) == 0) then {_games = +_catalogue};
private _invalidGames = _games select {(typeName _x) != "STRING" || {!(_x in _catalogue)}};
if ((count _invalidGames) > 0 || {(count _games) != (count (_games arrayIntersect _games))}) exitWith {[format ["unknown or duplicate game id(s): %1", _invalidGames]] call _reject};

private _validVectors = {
    params ["_vectors"];
    (typeName _vectors) == "ARRAY" && {(count _vectors) == 4} && {
        ({(typeName _x) == "ARRAY" && {(count _x) == 3} && {({(typeName _x) == "SCALAR"} count _x) == 3}} count _vectors) == 4
    }
};
if !([_seatOffsets] call _validVectors) exitWith {["seatOffsets must contain exactly four numeric XYZ vectors"] call _reject};
if !([_seatExitOffsets] call _validVectors) exitWith {["seatExitOffsets must contain exactly four numeric XYZ vectors"] call _reject};
if ((typeName _seatDirections) != "ARRAY" || {(count _seatDirections) != 4} || {({(typeName _x) == "SCALAR"} count _seatDirections) != 4}) exitWith {["seatDirections must contain exactly four numbers"] call _reject};
_seatOffsets = +_seatOffsets;
_seatExitOffsets = +_seatExitOffsets;
_seatDirections = +_seatDirections;
if ((typeName _actionRange) != "SCALAR" || {_actionRange <= 0} || {_actionRange > 25}) exitWith {["actionRange must be greater than zero and no more than 25 metres"] call _reject};

if !(call Waldo_fnc_MiniGamesEnsureRuntime) exitWith {["runtime compilation failed"] call _reject};
if (isNil {_table getVariable "Waldo_MG_LocalityHandlerLocal"}) then {
    private _localityHandler = _table addEventHandler ["Local", {
        params ["_localTable", "_isLocal"];
        if (_isLocal) then {[_localTable] call Waldo_MG_fnc_enforceInvulnerableLocal;};
    }];
    _table setVariable ["Waldo_MG_LocalityHandlerLocal", _localityHandler];
};
[_table] call Waldo_MG_fnc_enforceInvulnerableLocal;
private _canonical = [_displayName, _games, _seatOffsets, _seatExitOffsets, _seatDirections, _actionRange];
private _existing = _table getVariable ["Waldo_MG_TableRegistration", []];
if (isServer && {(count _existing) > 0} && {!(_existing isEqualTo _canonical)}) exitWith {["table is already registered with different settings"] call _reject};

if (isServer) then {
    _table setVariable ["Waldo_MG_TableRegistration", _canonical, true];
    _table setVariable ["Waldo_MG_TableDisplayName", _displayName, true];
    _table setVariable ["Waldo_MG_TableGames", _games, true];
    _table setVariable ["Waldo_MG_TableSeatOffsets", _seatOffsets, true];
    _table setVariable ["Waldo_MG_TableSeatExitOffsets", _seatExitOffsets, true];
    _table setVariable ["Waldo_MG_TableSeatDirections", _seatDirections, true];
    _table setVariable ["Waldo_MG_TableActionRange", _actionRange, true];
    [_table, "Composition", "COMPOSITION"] call Waldo_MG_fnc_markTableServer;

    private _registry = missionNamespace getVariable ["Waldo_MG_ServerRegistry", createHashMap];
    private _tableId = _table getVariable ["Waldo_MG_TableId", netId _table];
    if !(_tableId in _registry) then {
        _registry set [_tableId, createHashMapFromArray [["table", _table], ["options", _canonical], ["queue", []], ["draining", false], ["tokens", []]]];
        missionNamespace setVariable ["Waldo_MG_ServerRegistry", _registry];
        _table addEventHandler ["Deleted", {params ["_deletedTable"]; [_deletedTable] call Waldo_fnc_MiniGamesUnregisterTable;}];
    };
    [_table, _canonical] remoteExecCall ["Waldo_fnc_MiniGamesRegisterTableLocal", -2];
};
if (hasInterface) then {
    [_table, _canonical] call Waldo_fnc_MiniGamesRegisterTableLocal;
};
true

/*
 * Author: WaldoTheWarfighter
 * Apply one targeted MiniGames public-state snapshot and optionally open spectator presentation.
 *
 * Locality / Authority:
 * Interface client only. It updates only this client's copy of the registered table variables and
 * presentation; authoritative game state remains on the server.
 *
 * Repeat / JIP Behaviour:
 * Equivalent snapshots are repeat-safe. No executable JIP entry is used; JIP spectators request the
 * current snapshot only when they interact with a live table.
 *
 * Arguments:
 * 0: _table <OBJECT> - registered table
 * 1: _rows <ARRAY> - [variable name, value] public-state rows
 * 2: _revision <NUMBER> - current table revision
 * 3: _openSpectator <BOOLEAN> - open the spectator UI after applying state
 *
 * Return Value:
 * <BOOLEAN> - true when applied on an interface client
 *
 * Current Callers:
 * Waldo_MG_fnc_sendPublicTableSnapshotServer through MiniGamesSetSpectatorServer.
 *
 * Example:
 * [_table, [["Waldo_MG_ChessBoard", _board]], 7, true]
 *     call Waldo_fnc_MiniGamesApplyStateSnapshotLocal;
 */

params [
    ["_table", objNull, [objNull]],
    ["_rows", [], [[]]],
    ["_revision", -1, [0]],
    ["_openSpectator", false, [false]]
];
if (!hasInterface || {isNull _table}) exitWith {false};
if !(call Waldo_fnc_MiniGamesEnsureRuntime) exitWith {false};

{
    _x params [
        ["_variableName", "", [""]],
        ["_value", nil]
    ];
    if (_variableName != "") then {
        _table setVariable [_variableName, _value];
    };
} forEach _rows;

if (_openSpectator) then {
    [_table, true] call Waldo_MG_fnc_openSpectatorLocal;
} else {
    [_table, _revision] call Waldo_fnc_MiniGamesStateChangedLocal;
};
true

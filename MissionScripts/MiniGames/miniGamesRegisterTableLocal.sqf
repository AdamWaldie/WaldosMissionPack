/*
 * Author: WaldoTheWarfighter
 * Applies canonical registered-table metadata and installs table interactions on one interface client.
 *
 * Locality/authority: Interface clients install presentation. Headless clients compile only the
 * locality role needed if table ownership later migrates to them. It does not change server state.
 * Repeat/JIP: Repeat-safe; called after registration and during JIP metadata replay.
 * Arguments: 0 Object table; 1 Array canonical registration settings.
 * Return Value: Boolean - true when local presentation was installed.
 * Current callers: MiniGamesRegisterTable and server registration replay.
 * Example: [_table, _registration] call Waldo_fnc_MiniGamesRegisterTableLocal;
 */

params [["_table", objNull, [objNull]], ["_registration", [], [[]]]];
if (isNull _table || {(count _registration) != 6}) exitWith {false};
if !(call Waldo_fnc_MiniGamesEnsureRuntime) exitWith {false};
if (!hasInterface) exitWith {true};

_registration params ["_displayName", "_games", "_seatOffsets", "_seatExitOffsets", "_seatDirections", "_actionRange"];
_table setVariable ["Waldo_MG_TableDisplayName", _displayName];
_table setVariable ["Waldo_MG_TableGames", +_games];
_table setVariable ["Waldo_MG_TableSeatOffsets", +_seatOffsets];
_table setVariable ["Waldo_MG_TableSeatExitOffsets", +_seatExitOffsets];
_table setVariable ["Waldo_MG_TableSeatDirections", +_seatDirections];
_table setVariable ["Waldo_MG_TableActionRange", _actionRange];

private _known = +(missionNamespace getVariable ["Waldo_MG_DiscoveredTablesLocal", []]);
_known pushBackUnique _table;
missionNamespace setVariable ["Waldo_MG_DiscoveredTablesLocal", _known];
call Waldo_MG_fnc_ensureTableActionsLocal;
call Waldo_MG_fnc_ensurePlayerActionsLocal;
true

/*
 * Author: WaldoTheWarfighter
 * Applies one targeted registered-table metadata snapshot on an interface client.
 *
 * Locality/authority: Interface presentation only; never changes server state.
 * Repeat/JIP: Equivalent rows are repeat-safe and resolve cross-machine public-variable ordering.
 * Arguments: 0 Array - rows of [table Object, canonical registration Array].
 * Return Value: Boolean.
 * Current callers: MiniGamesRequestMetadataServer targeted response.
 * Example: [[[_table, _registration]]] call Waldo_fnc_MiniGamesApplyMetadataLocal;
 */

params [["_rows", [], [[]]]];
if (!hasInterface || {(count _rows) == 0}) exitWith {hasInterface};
if !(call Waldo_fnc_MiniGamesEnsureRuntime) exitWith {false};
{
    _x params [["_table", objNull, [objNull]], ["_registration", [], [[]]]];
    if (!isNull _table && {(count _registration) == 6}) then {
        [_table, _registration] call Waldo_fnc_MiniGamesRegisterTableLocal;
    };
} forEach _rows;
true

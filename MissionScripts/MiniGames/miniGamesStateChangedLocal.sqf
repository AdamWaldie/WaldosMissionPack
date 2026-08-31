/*
 * Author: WaldoTheWarfighter
 * Refreshes local seated/spectator presentation after a targeted table-state change notification.
 *
 * Locality/authority: Interface client only.
 * Repeat/JIP: Change notifications are idempotent; stale revisions are ignored.
 * Arguments: 0 Object table; 1 Number revision.
 * Return Value: Nothing.
 * Current callers: MiniGamesRequestServer queue drain.
 * Example: [_table, 7] call Waldo_fnc_MiniGamesStateChangedLocal;
 */

params [["_table", objNull, [objNull]], ["_revision", -1, [0]]];
if (!hasInterface || {isNull _table}) exitWith {};
private _key = format ["Waldo_MG_LastRevision_%1", _table getVariable ["Waldo_MG_TableId", netId _table]];
if (_revision <= (missionNamespace getVariable [_key, -1])) exitWith {};
missionNamespace setVariable [_key, _revision];
if ((player getVariable ["Waldo_MG_SeatedTable", objNull]) == _table || {(missionNamespace getVariable ["Waldo_MG_SpectatedTableLocal", objNull]) == _table}) then {
    call Waldo_MG_fnc_maintainSeatStateLocal;
    call Waldo_MG_fnc_maintainGameTransitionLocal;
    call Waldo_MG_fnc_maintainSpectatorStateLocal;
    call Waldo_MG_fnc_maintainSeatedScreenLocal;
};

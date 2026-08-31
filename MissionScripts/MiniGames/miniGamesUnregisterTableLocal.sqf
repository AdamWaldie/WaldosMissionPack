/*
 * Author: WaldoTheWarfighter
 * Removes local vanilla and ACE interaction state and closes displays belonging to one table.
 *
 * Locality/authority: Interface-client cleanup only.
 * Repeat/JIP: Repeat-safe; absent action identifiers are ignored.
 * Arguments: 0 Object - table being removed.
 * Return Value: Boolean.
 * Current callers: MiniGamesUnregisterTable locally and by targeted server notification.
 * Example: [_table] call Waldo_fnc_MiniGamesUnregisterTableLocal;
 */

params [["_table", objNull, [objNull]]];
if (!hasInterface || {isNull _table}) exitWith {true};
{
    _table removeAction _x;
} forEach (_table getVariable ["Waldo_MG_TableActionIdsLocal", []]);
_table setVariable ["Waldo_MG_TableActionIdsLocal", []];
if !(isNil "ace_interact_menu_fnc_removeActionFromObject") then {
    [_table, 0, ["ACE_MainActions", "Waldo_MG_TableCategory"]] call ace_interact_menu_fnc_removeActionFromObject;
};
_table setVariable ["Waldo_MG_TableACEActionsInstalled", false];
private _known = (missionNamespace getVariable ["Waldo_MG_DiscoveredTablesLocal", []]) - [_table];
missionNamespace setVariable ["Waldo_MG_DiscoveredTablesLocal", _known];
if ((player getVariable ["Waldo_MG_SeatedTable", objNull]) == _table || {(missionNamespace getVariable ["Waldo_MG_SpectatedTableLocal", objNull]) == _table}) then {
    call Waldo_MG_fnc_closeTableGameDisplaysLocal;
    [true] call Waldo_MG_fnc_exitSpectatorLocal;
};
true

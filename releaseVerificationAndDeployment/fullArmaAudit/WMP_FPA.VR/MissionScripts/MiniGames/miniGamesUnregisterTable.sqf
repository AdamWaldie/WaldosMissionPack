/*
 * Author: WaldoTheWarfighter
 * Removes a registered seated MiniGames table, releases its occupants, invalidates queued work, and
 * removes local interaction state. Object deletion calls this function automatically.
 *
 * Locality/authority: Safe on every machine. The server owns registry and seat cleanup; interface
 * clients own action and display cleanup.
 * Repeat/JIP: Repeat-safe. Unregistered tables are removed from the JIP metadata registry.
 * Arguments: 0 Object - registered table.
 * Return Value: Boolean - true when the call was valid or the table was already absent.
 * Current callers: Mission scripts and the registered table Deleted event handler.
 * Example: [this] call Waldo_fnc_MiniGamesUnregisterTable;
 */

params [["_table", objNull, [objNull]]];
if (isNull _table) exitWith {true};
if !(call Waldo_fnc_MiniGamesEnsureRuntime) exitWith {false};
private _localityHandler = _table getVariable ["Waldo_MG_LocalityHandlerLocal", -1];
if (_localityHandler >= 0) then {
    _table removeEventHandler ["Local", _localityHandler];
    _table setVariable ["Waldo_MG_LocalityHandlerLocal", nil];
};

if (isServer) then {
    _table setVariable ["Waldo_MG_TimerEpochServer", (_table getVariable ["Waldo_MG_TimerEpochServer", 0]) + 1];
    {
        if (!isNull _x) then {[_x] call Waldo_MG_fnc_releaseUnitSeatServer;};
    } forEach (_table getVariable ["Waldo_MG_TableSeats", []]);
    private _registry = missionNamespace getVariable ["Waldo_MG_ServerRegistry", createHashMap];
    _registry deleteAt (_table getVariable ["Waldo_MG_TableId", netId _table]);
    missionNamespace setVariable ["Waldo_MG_ServerRegistry", _registry];
    private _tables = (missionNamespace getVariable ["Waldo_MG_Tables", []]) - [_table];
    missionNamespace setVariable ["Waldo_MG_Tables", _tables, true];
    _table setVariable ["Waldo_MG_IsPartyTable", false, true];
    [_table] remoteExecCall ["Waldo_fnc_MiniGamesUnregisterTableLocal", -2];
};
if (hasInterface) then {[_table] call Waldo_fnc_MiniGamesUnregisterTableLocal;};
true

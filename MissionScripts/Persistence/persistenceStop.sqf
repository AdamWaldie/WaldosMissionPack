/*
 * Author: WaldoTheWarfighter
 * Stops WMP persistence loops without deleting any database records.
 *
 * Arguments:
 * 0: localOnly <BOOLEAN> - internal server broadcast flag
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_PersistenceStop;
 */

params [["_localOnly", false, [false]]];

private _stopClientLoop = {
    private _clientHandle = missionNamespace getVariable ["Waldo_Persistence_ClientLoop", scriptNull];
    if !(scriptDone _clientHandle) then {terminate _clientHandle};
    missionNamespace setVariable ["Waldo_Persistence_ClientStarted", false];
};

if !(isServer) exitWith {
    if !(_localOnly) then {[] remoteExecCall ["Waldo_fnc_PersistenceStop", 2]};
    call _stopClientLoop;
};

private _remoteAuthorized = true;
if (remoteExecutedOwner > 0) then {
    private _callerIndex = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_callerIndex >= 0) then {allPlayers select _callerIndex} else {objNull};
    _remoteAuthorized = !isNull _caller && {!isNull (getAssignedCuratorLogic _caller)};
};
if !(_remoteAuthorized) exitWith {};
if (remoteExecutedOwner > 0) exitWith {[] spawn Waldo_fnc_PersistenceStop};

{
    _x params ["_object", "_key", "_options"];
    if (!isNull _object) then {[_object, _key, _options] call Waldo_fnc_PersistenceSaveObject};
} forEach +(missionNamespace getVariable ["Waldo_Persistence_ObjectRegistry", []]);
missionNamespace setVariable ["Waldo_Persistence_Active", false, true];
private _handle = missionNamespace getVariable ["Waldo_Persistence_ServerLoop", scriptNull];
if !(scriptDone _handle) then {terminate _handle};
missionNamespace setVariable ["Waldo_Persistence_ServerStarted", false];
[true] remoteExecCall ["Waldo_fnc_PersistenceStop", -2];
// -2 ("all clients except owner 2") never reaches a listen server's own host client, since the
// host shares owner 2 with the embedded server - so on a listen server this machine's own
// Waldo_Persistence_ClientLoop (started under hasInterface in persistenceInit.sqf) was never
// terminated by the broadcast above. Stop it directly here too.
if (hasInterface) then {call _stopClientLoop};
diag_log "[WMP PERSISTENCE] Persistence stopped; stored records were retained.";

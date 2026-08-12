/*
 * Author: WaldoTheWarfighter
 * HandleDisconnect callback: when a connected headless client disconnects, returns every AI group it
 * was managing to the server and removes it from the headless registry, then runs a rebalance pass
 * so another connected headless client (if any) picks the orphaned groups back up. Event-driven - no
 * polling loop watches for headless-client disconnects.
 *
 * Locality and authority:
 * Server-only, fired by the engine's own HandleDisconnect mission event handler. A disconnecting
 * real player (not a headless client) is a no-op here - only owner ids present in
 * Waldo_Headless_Clients are acted on.
 *
 * Arguments (engine-supplied HandleDisconnect signature):
 * 0: unit <OBJECT> - the disconnecting network entity's object, still valid at this point; its
 *    owner id is read directly rather than trusting the engine's separate id/uid/name strings.
 * 1-3: id/uid/name <STRING> - unused.
 *
 * Return Value: Nothing.
 *
 * Example:
 * Installed once by initServer.sqf as:
 * addMissionEventHandler ["HandleDisconnect", {_this call Waldo_fnc_HeadlessReassignOnDisconnect}];
 */

params [["_unit", objNull, [objNull]]];
if !(isServer) exitWith {};
if (isNull _unit) exitWith {};

private _ownerId = owner _unit;
private _clients = missionNamespace getVariable ["Waldo_Headless_Clients", []];
private _idx = _clients findIf {(_x select 0) == _ownerId};
if (_idx < 0) exitWith {}; // a real player disconnected, not a registered headless client

private _label = (_clients select _idx) select 1;
_clients deleteAt _idx;
missionNamespace setVariable ["Waldo_Headless_Clients", _clients, true];
diag_log format ["[WMP HEADLESS] Headless client owner=%1 label=%2 disconnected; returning its groups to the server.", _ownerId, _label];

private _managed = missionNamespace getVariable ["Waldo_Headless_ManagedGroups", []];
private _orphaned = _managed select {(_x select 1) == _ownerId};
{
    private _group = _x select 0;
    if !(isNull _group) then {[_group, 2] call Waldo_fnc_HeadlessMigrateGroup;};
} forEach _orphaned;
["DISCONNECT", format [
    "owner=%1 label=%2 orphanedGroups=%3 remainingClients=%4",
    _ownerId, _label, count _orphaned, count _clients
]] call Waldo_fnc_HeadlessDebugLog;

[] call Waldo_fnc_HeadlessRebalance;

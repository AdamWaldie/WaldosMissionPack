/*
 * Author: Waldo
 * Stops every airborne-gunship system and optionally deletes system-spawned aircraft.
 * Arguments: 0: delete spawned aircraft <BOOLEAN>
 * Return Value: Number removed
 */

params [["_deleteSpawned", false, [false]]];
if !(isServer) exitWith {0};
if (remoteExecutedOwner > 0) then {
    private _callerIndex = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_callerIndex >= 0) then {allPlayers select _callerIndex} else {objNull};
    if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {0};
};
private _registry = missionNamespace getVariable ["Waldo_Gunship_Registry", createHashMap];
private _ids = keys _registry;
{[_x, _deleteSpawned] call Waldo_fnc_GunshipDestroy} forEach _ids;
missionNamespace setVariable ["Waldo_Gunship_Enable", false, true];
count _ids

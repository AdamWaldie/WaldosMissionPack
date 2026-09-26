/*
 * Author: WaldoTheWarfighter
 * Removes one registered gunship and optionally deletes a system-spawned aircraft.
 * Locality and authority: Server-only and curator-authenticated for remote requests; it owns
 * registry removal and object deletion, then asks the controller's client to release control.
 * Repeat/JIP: A removed ID cannot be destroyed again. The revised public state omits it for
 * current and joining clients.
 * Arguments: 0: id <STRING>; 1: delete spawned aircraft <BOOLEAN>
 * Return Value: Boolean
 * Current callers: gunship server controls and mission-maker cleanup scripts.
 * Example: ["SPECTRE_1", true] call Waldo_fnc_GunshipDestroy;
 * Result: The system is deregistered; its aircraft is deleted only if WMP spawned it and the
 * delete option was true.
 */

params ["_id", ["_deleteAircraft", false, [false]]];
if !(isServer) exitWith {false};
if (remoteExecutedOwner > 0) then {
    private _callerIndex = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_callerIndex >= 0) then {allPlayers select _callerIndex} else {objNull};
    if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {false};
};
private _registry = missionNamespace getVariable ["Waldo_Gunship_Registry", createHashMap];
if !(_id in keys _registry) exitWith {false};
private _state = _registry get _id;
private _handle = _state getOrDefault ["handle", scriptNull];
if !(isNull _handle) then {terminate _handle};
private _controller = _state getOrDefault ["controller", objNull];
if (!isNull _controller) then {[_id] remoteExecCall ["Waldo_fnc_GunshipReleaseControlLocal", owner _controller]};
private _aircraft = _state getOrDefault ["aircraft", objNull];
if (!isNull _aircraft) then {_aircraft setVariable ["Waldo_Gunship_Id", nil, true]};
if (_deleteAircraft && {_state getOrDefault ["spawned", false]} && {!isNull _aircraft}) then {
    {deleteVehicle _x} forEach crew _aircraft;
    deleteVehicle _aircraft;
};
_registry deleteAt _id;
missionNamespace setVariable ["Waldo_Gunship_Registry", _registry];
[] call Waldo_fnc_GunshipPublishState;
true

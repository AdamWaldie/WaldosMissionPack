/*
 * Author: Waldo
 * Spawns and transforms one validated object on the server.
 *
 * Arguments: 0: class <STRING>; 1: position <ARRAY>; 2: [pitch,bank,yaw] <ARRAY>; 3: mode <STRING>; 4: scale <NUMBER>; 5: placement <STRING>
 * Return Value: Object
 */

params [["_class", "", [""]], ["_position", [], [[]]], ["_angles", [0, 0, 0], [[]]], ["_mode", "ATL", [""]], ["_scale", 1, [0]], ["_placement", "CAN_COLLIDE", [""]]];
if !(isServer) exitWith {[_class, _position, _angles, _mode, _scale, _placement] remoteExecCall ["Waldo_fnc_ObjectTransformSpawn", 2]; objNull};
if !(isClass (configFile >> "CfgVehicles" >> _class)) exitWith {objNull};
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {objNull};
};
private _object = createVehicle [_class, [0, 0, 0], [], 0, _placement];
[_object, _position, _angles, _mode, _scale] call Waldo_fnc_ObjectTransformSet

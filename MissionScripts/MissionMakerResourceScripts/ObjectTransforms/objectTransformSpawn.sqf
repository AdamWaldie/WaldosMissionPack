/*
 * Author: WaldoTheWarfighter
 * Spawns and transforms one validated object on the server.
 * Locality and authority: Server validates the class and remote curator identity, creates the
 * object, then delegates its transform to Waldo_fnc_ObjectTransformSet. Clients only forward.
 * Repeat/JIP: Every accepted call spawns another object. It has no deduplication key; the
 * spawned network object is visible to joining clients.
 *
 * Waldo_fnc_ObjectTransformSet performs position and orientation before optional scaling. Runtime
 * scaling normally converts the new grounded decorative object to a Simple Object. Currently called
 * directly by mission scripts and inventoried by the full-pack function station.
 *
 * Arguments:
 * 0: class <STRING>
 * 1: position <ARRAY>
 * 2: [pitch, bank, yaw] <ARRAY>
 * 3: position mode ATL|ASL|ASLW <STRING> (default: ATL)
 * 4: scale <NUMBER> (default: 1)
 * 5: placement mode <STRING> (default: CAN_COLLIDE)
 * 6: convertToSimpleObject <BOOLEAN> (default: true when scaling is requested)
 *
 * Return Value:
 * Object - spawned object (possibly a Simple Object), or objNull
 *
 * Example:
 * private _prop = ["Land_CampingChair_V2_F", [100, 100, 0], [0, 0, 90], "ATL", 1.5, "CAN_COLLIDE", true] call Waldo_fnc_ObjectTransformSpawn;
 * Result: The server returns the spawned/transformed Object or objNull. A client call returns
 * objNull before the server creates anything.
 * Current callers: Mission scripts using Waldo_fnc_ObjectTransformSpawn and the full-pack audit station.
 */

params [["_class", "", [""]], ["_position", [], [[]]], ["_angles", [0, 0, 0], [[]]], ["_mode", "ATL", [""]], ["_scale", 1, [0]], ["_placement", "CAN_COLLIDE", [""]], ["_asSimple", true, [false]]];
if !(isServer) exitWith {[_class, _position, _angles, _mode, _scale, _placement, _asSimple] remoteExecCall ["Waldo_fnc_ObjectTransformSpawn", 2]; objNull};
if !(isClass (configFile >> "CfgVehicles" >> _class)) exitWith {objNull};
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {objNull};
};
private _object = createVehicle [_class, [0, 0, 0], [], 0, _placement];
[_object, _position, _angles, _mode, _scale, _asSimple && {_scale != 1}] call Waldo_fnc_ObjectTransformSet

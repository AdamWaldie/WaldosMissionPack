/*
 * Author: Waldo
 * Applies a server-validated position, pitch/bank/yaw orientation and optional uniform scale.
 *
 * Arguments: 0: object <OBJECT>; 1: position <ARRAY>; 2: [pitch,bank,yaw] <ARRAY>; 3: ATL|ASL|ASLW <STRING>; 4: scale <NUMBER>, -1 unchanged
 * Return Value: Object
 */

params [["_object", objNull, [objNull]], ["_position", [], [[]]], ["_angles", [0, 0, 0], [[]]], ["_mode", "ATL", [""]], ["_scale", -1, [0]]];
if !(isServer) exitWith {[_object, _position, _angles, _mode, _scale] remoteExecCall ["Waldo_fnc_ObjectTransformSet", 2]; _object};
if (isNull _object || {count _position < 2}) exitWith {objNull};
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {objNull};
};
switch (toUpperANSI _mode) do {
    case "ASL": {_object setPosASL _position};
    case "ASLW": {_object setPosASLW _position};
    default {_object setPosATL _position};
};
_angles params [["_pitch", 0], ["_bank", 0], ["_yaw", 0]];
private _direction = [sin _yaw * cos _pitch, cos _yaw * cos _pitch, sin _pitch];
private _up = [
    sin _bank * cos _yaw - cos _bank * sin _pitch * sin _yaw,
    -sin _bank * sin _yaw - cos _bank * sin _pitch * cos _yaw,
    cos _bank * cos _pitch
];
_object setVectorDirAndUp [_direction, _up];
if (_scale > 0) then {[_object, _scale, false] call Waldo_fnc_ObjectScale};
_object

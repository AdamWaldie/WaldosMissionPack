/*
 * Author: Waldo
 * Spawns one breach replacement relative to the original object's full transform.
 *
 * Arguments:
 * 0: original <OBJECT>
 * 1: specification <ARRAY> - class, model offset, yaw or [pitch,bank,yaw], placement, position mode, scale
 *
 * Return Value:
 * Object - spawned replacement or objNull
 *
 * Example:
 * [_wall, ["Land_BagFence_Long_F", [0,0,0], [0,0,90], "CAN_COLLIDE", "ATL", 1]] call Waldo_fnc_BreachingSpawnRelative;
 */

params ["_original", "_specification"];
if !(isServer) exitWith {objNull};
if (isNull _original || {count _specification < 2}) exitWith {objNull};

_specification params [
    ["_className", "", [""]],
    ["_offset", [0, 0, 0], [[]]],
    ["_rotation", 0, [0, []]],
    ["_placement", "CAN_COLLIDE", [""]],
    ["_positionMode", "ATL", [""]],
    ["_scale", 1, [0]]
];
if !(isClass (configFile >> "CfgVehicles" >> _className)) exitWith {
    diag_log format ["[WMP BREACHING] Replacement classname '%1' is invalid.", _className];
    objNull
};

private _positionATL = _original modelToWorld _offset;
private _spawned = createVehicle [_className, [0, 0, 0], [], 0, _placement];
switch (toUpperANSI _positionMode) do {
    case "ASL": {_spawned setPosASL (AGLToASL _positionATL)};
    case "ASLW": {_spawned setPosASLW (AGLToASL _positionATL)};
    default {_spawned setPosATL _positionATL};
};

private _angles = if (_rotation isEqualType 0) then {[0, 0, getDir _original + _rotation]} else {+_rotation};
_angles params [["_pitch", 0], ["_bank", 0], ["_yaw", getDir _original]];
if (_rotation isEqualType []) then {_yaw = getDir _original + _yaw};
private _direction = [sin _yaw * cos _pitch, cos _yaw * cos _pitch, sin _pitch];
private _up = [
    sin _bank * cos _yaw - cos _bank * sin _pitch * sin _yaw,
    -sin _bank * sin _yaw - cos _bank * sin _pitch * cos _yaw,
    cos _bank * cos _pitch
];
_spawned setVectorDirAndUp [_direction, _up];
_spawned setObjectScale ((_scale max 0.01) min (missionNamespace getVariable ["Waldo_ObjectScaling_Maximum", 10]));
_spawned

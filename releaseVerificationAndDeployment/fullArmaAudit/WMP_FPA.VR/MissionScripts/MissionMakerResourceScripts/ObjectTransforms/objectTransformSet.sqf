/*
 * Author: WaldoTheWarfighter
 * Applies a server-validated position, pitch/bank/yaw orientation and optional uniform scale.
 *
 * Position and direction are applied before scaling because Arma direction commands reset scale.
 * Scaling an ordinary free-standing object requires explicit Simple Object conversion. Currently
 * called by Waldo_fnc_ObjectTransformSpawn and the full-pack transform audit station.
 *
 * Arguments:
 * 0: object <OBJECT>
 * 1: position <ARRAY>
 * 2: [pitch, bank, yaw] <ARRAY>
 * 3: position mode ATL|ASL|ASLW <STRING> (default: ATL)
 * 4: scale <NUMBER> - negative leaves scale unchanged (default: -1)
 * 5: convertToSimpleObject <BOOLEAN> - grounded decorative objects only (default: false)
 *
 * Return Value:
 * Object - transformed object (possibly a replacement), or objNull
 *
 * Example:
 * private _result = [prop, [100, 100, 0], [0, 0, 45], "ATL", 1.5, true] call Waldo_fnc_ObjectTransformSet;
 */

params [["_object", objNull, [objNull]], ["_position", [], [[]]], ["_angles", [0, 0, 0], [[]]], ["_mode", "ATL", [""]], ["_scale", -1, [0]], ["_asSimple", false, [false]]];
if !(isServer) exitWith {[_object, _position, _angles, _mode, _scale, _asSimple] remoteExecCall ["Waldo_fnc_ObjectTransformSet", 2]; _object};
if (isNull _object || {count _position < 2}) exitWith {objNull};
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {objNull};
};
// Capture scale before any position/direction work. Arma resets the transformation matrix scale to
// 1 when direction or orientation changes, so an omitted scale means "preserve current scale", not
// "allow this transform to silently undo prior scaling".
private _existingScale = getObjectScale _object;
private _scaleToApply = if (_scale > 0) then {_scale} else {_existingScale};
private _reapplyScale = _scale > 0 || {abs (_existingScale - 1) > 0.001};
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
if (_reapplyScale) exitWith {[_object, _scaleToApply, _asSimple] call Waldo_fnc_ObjectScale};
_object

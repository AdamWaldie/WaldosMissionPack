/*
 * Author: WaldoTheWarfighter
 * Applies a validated uniform render scale to one server-authoritative object.
 *
 * Arma officially supports runtime scaling only for Simple Objects and attached objects. Disabling
 * simulation on an ordinary object is not sufficient. When conversion is requested, the target must
 * be an empty, grounded decorative object; it is replaced with a Simple Object and therefore loses
 * simulation, damage, inventory, crew, addAction support and its original object reference. The
 * returned object and any Eden variable-name binding must be used after conversion. Direction and
 * orientation changes must happen before this function because they reset scale to 1.
 *
 * The server validates curator/client requests and applies the globally effective scale. Current
 * callers are ObjectScaleTagged, ObjectScaleReset, ObjectScaleMultiply, ObjectScaleCopy,
 * ObjectScaleArea, ObjectTransformSet, ObjectScaleZen and the full-pack audit station.
 *
 * Arguments:
 * 0: object <OBJECT>
 * 1: scale <NUMBER>
 * 2: convertToSimpleObject <BOOLEAN> - replace unsupported ordinary objects first (default: false)
 *
 * Return Value:
 * Object - scaled object (which may be a replacement), or objNull when rejected/unsupported
 *
 * Example:
 * private _scaled = [this, 1.5, true] call Waldo_fnc_ObjectScale;
 */

params [
    ["_object", objNull, [objNull]],
    ["_scale", 1, [0]],
    ["_asSimple", false, [false]]
];
if !(isServer) exitWith {
    [_object, _scale, _asSimple] remoteExecCall ["Waldo_fnc_ObjectScale", 2];
    _object
};
if (isNull _object) exitWith {objNull};

private _remoteAuthorized = true;
if (remoteExecutedOwner > 0) then {
    private _callerIndex = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_callerIndex >= 0) then {allPlayers select _callerIndex} else {objNull};
    private _isCurator = !isNull _caller && {!isNull (getAssignedCuratorLogic _caller)};
    _remoteAuthorized = _isCurator || {missionNamespace getVariable ["Waldo_ObjectScaling_AllowClientRequests", false]};
};
if !(_remoteAuthorized) exitWith {objNull};

private _minimum = missionNamespace getVariable ["Waldo_ObjectScaling_Minimum", 0.1];
private _maximum = missionNamespace getVariable ["Waldo_ObjectScaling_Maximum", 10];
_scale = (_scale max _minimum) min _maximum;

private _scaledObject = _object;
private _originalScale = _object getVariable ["Waldo_ObjectScaleOriginal", getObjectScale _object];
if (_asSimple && {!isSimpleObject _object}) then {
    if (count (crew _object) > 0 || {(getPosATL _object select 2) > 0.5}) exitWith {objNull};
    private _variableName = vehicleVarName _object;
    _scaledObject = [_object] call BIS_fnc_replaceWithSimpleObject;
    if (isNull _scaledObject) exitWith {objNull};
    if (_variableName != "") then {
        _scaledObject setVehicleVarName _variableName;
        missionNamespace setVariable [_variableName, _scaledObject, true];
    };
    { _x addCuratorEditableObjects [[_scaledObject], false] } forEach allCurators;
};
if (!isSimpleObject _scaledObject && {isNull (attachedTo _scaledObject)}) exitWith {objNull};
_scaledObject setObjectScale _scale;
if (abs ((getObjectScale _scaledObject) - _scale) > 0.001) exitWith {objNull};
_scaledObject setVariable ["Waldo_ObjectScaleOriginal", _originalScale, true];
_scaledObject setVariable ["Waldo_ObjectScale", _scale, true];
_scaledObject

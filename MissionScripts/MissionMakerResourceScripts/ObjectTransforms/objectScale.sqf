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
private _requestOwner = remoteExecutedOwner;
private _reject = {
    params ["_message"];
    diag_log format ["[WMP OBJECT SCALE] Rejected: %1", _message];
    if (_requestOwner > 2) then {
        ["OBJECT SCALE", _message, "ERROR", "OBJECT_SCALE_ZEN", 7] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _requestOwner];
    };
    objNull
};
if (isNull _object) exitWith {["No valid object reached the server."] call _reject};

private _remoteAuthorized = true;
if (remoteExecutedOwner > 0) then {
    private _callerIndex = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_callerIndex >= 0) then {allPlayers select _callerIndex} else {objNull};
    private _isCurator = !isNull _caller && {!isNull (getAssignedCuratorLogic _caller)};
    _remoteAuthorized = _isCurator || {missionNamespace getVariable ["Waldo_ObjectScaling_AllowClientRequests", false]};
};
if !(_remoteAuthorized) exitWith {["Only an assigned curator may scale objects through the ZEN module."] call _reject};

private _minimum = missionNamespace getVariable ["Waldo_ObjectScaling_Minimum", 0.1];
private _maximum = missionNamespace getVariable ["Waldo_ObjectScaling_Maximum", 10];
_scale = (_scale max _minimum) min _maximum;

private _scaledObject = _object;
private _originalScale = _object getVariable ["Waldo_ObjectScaleOriginal", getObjectScale _object];
if (_asSimple && {!isSimpleObject _object} && {count (crew _object) > 0 || {(getPosATL _object select 2) > 1}}) exitWith {
    ["Conversion requires an empty decorative object resting on the ground."] call _reject
};
if (_asSimple && {!isSimpleObject _object}) then {
    private _variableName = vehicleVarName _object;
    _scaledObject = [_object] call BIS_fnc_replaceWithSimpleObject;
    if (!isNull _scaledObject && {_variableName != ""}) then {
        _scaledObject setVehicleVarName _variableName;
        missionNamespace setVariable [_variableName, _scaledObject, true];
    };
    if (!isNull _scaledObject) then {{_x addCuratorEditableObjects [[_scaledObject], false]} forEach allCurators};
};
if (isNull _scaledObject) exitWith {["Arma could not convert this class to a Simple Object."] call _reject};
if (!isSimpleObject _scaledObject && {isNull (attachedTo _scaledObject)}) exitWith {["Arma supports scaling only Simple Objects or attached objects. Enable decorative-object conversion for this target."] call _reject};
_scaledObject setObjectScale _scale;
if (abs ((getObjectScale _scaledObject) - _scale) > 0.001) exitWith {["Arma did not retain the requested scale for this object class."] call _reject};
_scaledObject setVariable ["Waldo_ObjectScaleOriginal", _originalScale, true];
_scaledObject setVariable ["Waldo_ObjectScale", _scale, true];
diag_log format ["[WMP OBJECT SCALE] Applied scale=%1 class=%2 simple=%3 object=%4", _scale, typeOf _scaledObject, isSimpleObject _scaledObject, _scaledObject];
if (_requestOwner > 2) then {
    ["OBJECT SCALE", format ["%1 scaled to %2x and verified by the server.", getText (configOf _scaledObject >> "displayName"), _scale], "SUCCESS", "OBJECT_SCALE_ZEN", 5] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _requestOwner];
};
_scaledObject

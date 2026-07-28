/*
 * Author: Waldo
 * Applies a validated scale to one object on the server, optionally converting it to a simple object.
 *
 * Arguments:
 * 0: object <OBJECT>
 * 1: scale <NUMBER>
 * 2: asSimpleObject <BOOLEAN> - replace with a simple object first (default: false)
 *
 * Return Value:
 * Object - scaled object on server, or objNull when rejected
 *
 * Example:
 * [this, 1.5, false] call Waldo_fnc_ObjectScale;
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
private _originalScale = _object getVariable ["Waldo_ObjectScaleOriginal", _object getVariable ["Waldo_ObjectScale", 1]];
if (_asSimple && {!isSimpleObject _object}) then {
    _scaledObject = _object call BIS_fnc_replaceWithSimpleObject;
};
_scaledObject setObjectScale _scale;
_scaledObject setVariable ["Waldo_ObjectScaleOriginal", _originalScale, true];
_scaledObject setVariable ["Waldo_ObjectScale", _scale, true];
_scaledObject

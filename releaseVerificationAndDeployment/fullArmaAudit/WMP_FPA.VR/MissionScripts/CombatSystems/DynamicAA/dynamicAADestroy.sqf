/*
 * Author: Waldo
 * Disables and optionally removes one named Dynamic AA system without affecting other instances.
 *
 * Arguments:
 * 0: id <STRING>
 * 1: deleteAssets <BOOLEAN> - delete spawned assets and markers (default: true)
 *
 * Return Value:
 * Boolean - true when the system existed
 *
 * Example:
 * ["north_sector", true] call Waldo_fnc_DynamicAADestroy;
 */

params [
    ["_id", "", [""]],
    ["_deleteAssets", true, [false]]
];
if !(isServer) exitWith {
    [_id, _deleteAssets] remoteExecCall ["Waldo_fnc_DynamicAADestroy", 2];
    true
};
private _remoteAuthorized = true;
if (remoteExecutedOwner > 0) then {
    private _callerIndex = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_callerIndex >= 0) then {allPlayers select _callerIndex} else {objNull};
    _remoteAuthorized = !isNull _caller && {!isNull (getAssignedCuratorLogic _caller)};
};
if !(_remoteAuthorized) exitWith {false};
private _registry = missionNamespace getVariable ["Waldo_DynamicAA_Registry", createHashMap];
if !(_id in (keys _registry)) exitWith {false};
private _state = _registry get _id;
_state set ["active", false];
{
    if (!isNull _x) then {[_x, false] call Waldo_fnc_DynamicAASetGroupState};
} forEach (_state getOrDefault ["defenceGroups", []]);
private _handle = _state getOrDefault ["handle", scriptNull];
if !(scriptDone _handle) then {terminate _handle};

if (_deleteAssets) then {
    {
        if (!isNull _x) then {
            {if (!isNull _x) then {deleteVehicle _x}} forEach crew _x;
            deleteVehicle _x;
        };
    } forEach (_state getOrDefault ["objects", []]);
    {
        if (!isNull _x) then {
            {if (!isNull _x) then {deleteVehicle _x}} forEach units _x;
            deleteGroup _x;
        };
    } forEach (_state getOrDefault ["groups", []]);
    {deleteMarker _x} forEach (_state getOrDefault ["markers", []]);
    _registry deleteAt _id;
} else {
    {
        _x setMarkerColor "ColorGrey";
        if (markerShape _x == "ICON") then {_x setMarkerText format ["%1 AA disabled", _id]};
    } forEach (_state getOrDefault ["markers", []]);
    _registry set [_id, _state];
};
missionNamespace setVariable ["Waldo_DynamicAA_Registry", _registry];
[] call Waldo_fnc_DynamicAAPublishState;
true

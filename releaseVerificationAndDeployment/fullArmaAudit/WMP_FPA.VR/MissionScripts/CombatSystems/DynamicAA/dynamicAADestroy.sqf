/*
 * Author: WaldoTheWarfighter
 * Disables and optionally removes one named Dynamic AA system without affecting other instances.
 *
 * Locality and authority:
 * The server owns registry, markers, asset deletion and final state. A client call is sent to the
 * server and accepted only from an assigned curator, except the validated radar shutdown procedure.
 * Retained assets are disarmed and their AI gate is closed; removed systems disappear from the next
 * published snapshot. Repeating the call after removal returns false without creating side effects.
 *
 * Arguments:
 * 0: id <STRING>
 * 1: deleteAssets <BOOLEAN> - delete spawned assets and markers (default: true)
 * 2: completed interaction radar <OBJECT> - internal authority proof supplied only by the shared
 *      radar procedure callback (default objNull)
 *
 * Return Value:
 * Boolean - true when the system existed
 *
 * Current callers:
 * Dynamic AA ZEN removal, radar-loss detector handling, shared shutdown interaction and scripts.
 *
 * Example:
 * ["north_sector", true] call Waldo_fnc_DynamicAADestroy;
 * Result: the system is removed, or retained visibly disabled when deleteAssets is false.
 */

params [
    ["_id", "", [""]],
    ["_deleteAssets", true, [false]],
    ["_interactionRadar", objNull, [objNull]]
];
if !(isServer) exitWith {
    [_id, _deleteAssets, objNull] remoteExecCall ["Waldo_fnc_DynamicAADestroy", 2];
    true
};
private _interactionAuthorised = !_deleteAssets
    && {!isNull _interactionRadar}
    && {(_interactionRadar getVariable ["Waldo_DynamicAA_SystemId", ""]) == _id}
    && {(_interactionRadar getVariable ["Waldo_MG_InteractionState", "IDLE"]) == "SUCCESS"};
private _remoteAuthorized = true;
if (remoteExecutedOwner > 0 && {!_interactionAuthorised}) then {
    private _callerIndex = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_callerIndex >= 0) then {allPlayers select _callerIndex} else {objNull};
    _remoteAuthorized = !isNull _caller && {!isNull (getAssignedCuratorLogic _caller)};
};
if !(_remoteAuthorized) exitWith {false};
private _registry = missionNamespace getVariable ["Waldo_DynamicAA_Registry", createHashMap];
if !(_id in (keys _registry)) exitWith {false};
private _state = _registry get _id;
private _displayName = (_state get "config") getOrDefault ["displayName", _id];
_state set ["active", false];
{
    if (!isNull _x) then {_x setVariable ["Waldo_DynamicAA_InteractionAvailable", false, true]};
} forEach (_state getOrDefault ["radars", [_state getOrDefault ["radar", objNull]]]);
{
    if (!isNull _x) then {[_x, false] call Waldo_fnc_DynamicAASetGroupState};
} forEach (_state getOrDefault ["defenceGroups", []]);
{
    if (!isNull _x && {_x isKindOf "AllVehicles"}) then {
        [_x, 0] call Waldo_fnc_DynamicAASetVehicleAmmo;
    };
} forEach (_state getOrDefault ["objects", []]);
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
        if (markerShape _x == "ICON") then {_x setMarkerText format ["%1 - disabled", _displayName]};
    } forEach (_state getOrDefault ["markers", []]);
    _registry set [_id, _state];
};
missionNamespace setVariable ["Waldo_DynamicAA_Registry", _registry];
[] call Waldo_fnc_DynamicAAPublishState;
true

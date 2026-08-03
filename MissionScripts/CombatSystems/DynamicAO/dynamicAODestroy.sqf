/*
 * Author: WaldoTheWarfighter
 * Deletes one complete server-owned Dynamic AO and every tracked entity, group and marker.
 *
 * The registry entry is removed before world deletion so deleting the hidden AO anchor cannot
 * recursively start cleanup. Called directly by mission scripts, the ZEN cleanup module and the
 * anchor Deleted event handler.
 *
 * Arguments:
 * 0: AO id <STRING>
 *
 * Return Value:
 * Boolean - true when a registered AO was removed
 *
 * Current callers: mission scripts, DynamicAORemoveZen and centre-anchor Deleted handlers.
 *
 * Example:
 * ["AO_NORTH"] call Waldo_fnc_DynamicAODestroy;
 */
params [["_id", "", [""]]];
if !(isServer) exitWith {[_id] remoteExecCall ["Waldo_fnc_DynamicAODestroy", 2]; true};
private _registry = missionNamespace getVariable ["Waldo_DynamicAO_Registry", createHashMap];
if !(_id in keys _registry) exitWith {false};
private _state = _registry get _id;
_registry deleteAt _id;
missionNamespace setVariable ["Waldo_DynamicAO_Registry", _registry];

{
    private _field = _x;
    {if (!isNull _x) then {deleteVehicle _x}} forEach (_field getOrDefault ["mines", []]);
    {if (_x != "") then {deleteMarker _x}} forEach (_field getOrDefault ["markers", []]);
    private _fieldAnchor = _field getOrDefault ["anchor", objNull];
    if (!isNull _fieldAnchor) then {deleteVehicle _fieldAnchor};
} forEach (_state getOrDefault ["minefields", []]);
{if (!isNull _x) then {deleteVehicle _x}} forEach (_state getOrDefault ["objects", []]);
{
    if (!isNull _x) then {
        {if (!isNull _x) then {deleteVehicle _x}} forEach units _x;
        deleteGroup _x;
    };
} forEach (_state getOrDefault ["groups", []]);
{if (_x != "") then {deleteMarker _x}} forEach (_state getOrDefault ["markers", []]);
[] call Waldo_fnc_DynamicAOPublishState;
diag_log format ["[WMP DYNAMIC AO] Removed '%1'.", _id];
true

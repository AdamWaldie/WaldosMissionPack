/*
 * Author: WaldoTheWarfighter
 * Removes one tracked minefield without affecting the rest of its Dynamic AO.
 *
 * This server-owned callback is normally triggered when Zeus deletes a minefield anchor. It is
 * repeat-safe and also supports direct scripted cleanup by AO id and field index.
 *
 * Arguments:
 * 0: AO id <STRING>
 * 1: minefield index <NUMBER>
 *
 * Return Value:
 * Boolean - true when a live field was removed
 *
 * Current callers: mission scripts and each generated minefield anchor's Deleted handler.
 *
 * Example:
 * ["AO_NORTH", 0] call Waldo_fnc_DynamicAODestroyMinefield;
 */
params [["_id", "", [""]], ["_index", -1, [0]]];
if !(isServer) exitWith {[_id, _index] remoteExecCall ["Waldo_fnc_DynamicAODestroyMinefield", 2]; true};
private _registry = missionNamespace getVariable ["Waldo_DynamicAO_Registry", createHashMap];
if !(_id in keys _registry) exitWith {false};
private _state = _registry get _id;
private _fields = _state getOrDefault ["minefields", []];
if (_index < 0 || {_index >= count _fields}) exitWith {false};
private _field = _fields select _index;
if !(_field getOrDefault ["active", false]) exitWith {false};
_field set ["active", false];
{if (!isNull _x) then {deleteVehicle _x}} forEach (_field getOrDefault ["mines", []]);
{if (_x != "") then {deleteMarker _x}} forEach (_field getOrDefault ["markers", []]);
private _anchor = _field getOrDefault ["anchor", objNull];
if (!isNull _anchor) then {deleteVehicle _anchor};
_fields set [_index, _field];
_state set ["minefields", _fields];
_registry set [_id, _state];
missionNamespace setVariable ["Waldo_DynamicAO_Registry", _registry];
[] call Waldo_fnc_DynamicAOPublishState;
true

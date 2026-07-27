/* Removes a marker created by Waldo_fnc_Create3DMarker. */
params [["_id", "", [""]]];
if (_id isEqualTo "") exitWith {false};
if (!isServer) exitWith {[_id] remoteExecCall ["Waldo_fnc_Remove3DMarker", 2]; true};
private _registry = +(missionNamespace getVariable ["Waldo_3DMarker_Registry", []]);
private _index = _registry findIf {(_x param [0, ""]) isEqualTo _id};
if (_index < 0) exitWith {false};
_registry deleteAt _index;
missionNamespace setVariable ["Waldo_3DMarker_Registry", _registry, true];
true

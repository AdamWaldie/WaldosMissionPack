/*
 * Author: WaldoTheWarfighter
 * Permanently removes a jammer from the registry (and its map marker), optionally deleting the
 * emitter object too. Server-authoritative - calling on a client forwards to the server, which
 * re-broadcasts the updated registry so the jammer stops affecting every machine.
 *
 * Arguments:
 * 0: Reference <OBJECT or NUMBER> - the jammer object, or its jammer id (from Waldo_fnc_Jammer)
 * 1: Delete object <BOOL> - also deleteVehicle the emitter object (optional, default: false)
 *
 * Return Value:
 * Bool <BOOL> - true if a matching jammer was found and removed (server side)
 *
 * Example:
 * [myJammer, true] call Waldo_fnc_JammerRemove;   // remove jammer and delete its object
 * [3] call Waldo_fnc_JammerRemove;                // remove jammer id 3, keep the object
 */

params [["_ref", objNull], ["_deleteObject", false]];

if (!isServer) exitWith {
    _this remoteExec ["Waldo_fnc_JammerRemove", 2];
    false
};

// Resolve the target id from either an object or a raw id.
private _id = -1;
if (_ref isEqualType objNull) then {
    _id = _ref getVariable ["Waldo_Jamming_Id", -1];
} else {
    if (_ref isEqualType 0) then { _id = _ref; };
};
if (_id < 0) exitWith { false };

private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
private _idx = _registry findIf { (_x select 0) == _id };
if (_idx < 0) exitWith { false };

private _entry = _registry select _idx;
private _obj = _entry select 1;
private _markerName = _entry select 8;

// Tidy up the marker.
if (_markerName != "" && {getMarkerType _markerName != ""}) then { deleteMarker _markerName; };

// Drop the entry and re-broadcast.
_registry deleteAt _idx;
missionNamespace setVariable ["Waldo_Jamming_Registry", _registry, true];

// Optionally remove the emitter object.
if (_deleteObject && {!isNull _obj}) then {
    _obj setVariable ["Waldo_Jamming_Id", nil, true];
    deleteVehicle _obj;
};

diag_log format ["[WMP JAM] Jammer %1 removed.", _id];

true

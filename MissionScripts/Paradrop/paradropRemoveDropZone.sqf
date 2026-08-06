/*
 * Author: WaldoTheWarfighter
 * Removes one server-owned paradrop operation, boarding points, aircraft/embarked generated AI
 * and global markers.
 * Generated troops that have already jumped are deliberately left in the mission; removing an
 * operation is not a remote-delete mechanism for deployed infantry. Aircraft deletion is safely
 * suppressed while players remain aboard. Empty owned groups are cleaned.
 *
 * Arguments:
 * 0: operation ID <STRING>
 * 1: delete aircraft <BOOL> (default true)
 * 2: requester <OBJECT> (default objNull) - curator authorization for remote calls
 * 3: notify requester <BOOL> (default true)
 * 4: delete markers <BOOL> (default true) - explicit removal (this function called directly, e.g.
 *    the ZEN "Remove Operation" module) defaults to tearing down the markers along with everything
 *    else. Automatic cleanup on DESPAWN/aircraft loss instead passes the operation's own configured
 *    removeMarkersOnCleanup option here (default false there - see Waldo_fnc_ParadropCreateDropZone),
 *    so a map marker isn't yanked out from under a mission maker who wanted it left in place.
 *
 * Return Value: Boolean - true when a registered operation was removed.
 *
 * Example: ["DZ_ALPHA", true, player, true] remoteExecCall ["Waldo_fnc_ParadropRemoveDropZone", 2];
 * Current callers: ParadropRemoveDropZoneZen, automatic run cleanup and mission scripts.
 */
params [["_id", "", [""]], ["_deleteAircraft", true, [false]], ["_requester", objNull, [objNull]], ["_notifyRequester", true, [false]], ["_deleteMarkers", true, [false]]];
if (!isServer) exitWith {_this remoteExecCall ["Waldo_fnc_ParadropRemoveDropZone", 2]; true};
if (remoteExecutedOwner > 0) then {
    if (isNull _requester || {owner _requester != remoteExecutedOwner} || {isNull getAssignedCuratorLogic _requester}) exitWith {false};
};
private _registry = missionNamespace getVariable ["Waldo_Paradrop_DropZones", createHashMap];
if !(_id in keys _registry) exitWith {false};
private _state = _registry get _id;
if (_deleteMarkers) then {{deleteMarker _x} forEach (_state getOrDefault ["markers", []])};
{if (!isNull _x) then {deleteVehicle _x}} forEach (_state getOrDefault ["boardingPoints", []]);
private _aircraft = _state getOrDefault ["aircraft", objNull];
if (_deleteAircraft && {!isNull _aircraft} && {(crew _aircraft) findIf {isPlayer _x} >= 0}) then {
    _deleteAircraft = false;
    diag_log format ["[WMP PARADROP] Aircraft deletion suppressed because players remain aboard id=%1", _id];
    if (!isNull _requester && {_notifyRequester}) then {
        ["DYNAMIC PARADROP", "Operation and markers removed, but the aircraft was retained because players are aboard.", "WARNING", "PARADROP_REMOVE", 8] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _requester];
    };
};
if (_deleteAircraft && {!isNull _aircraft}) then {deleteVehicleCrew _aircraft; deleteVehicle _aircraft};
if (_deleteAircraft) then {
    {
        if (!isNull _x && {!isPlayer _x} && {vehicle _x == _aircraft}) then {deleteVehicle _x};
    } forEach (_state getOrDefault ["jumpers", []]);
};
private _flightGroup = _state getOrDefault ["flightGroup", grpNull];
if (!isNull _flightGroup && {count units _flightGroup == 0}) then {deleteGroup _flightGroup};
private _jumpGroup = _state getOrDefault ["jumpGroup", grpNull];
if (!isNull _jumpGroup && {count units _jumpGroup == 0}) then {deleteGroup _jumpGroup};
_registry deleteAt _id;
missionNamespace setVariable ["Waldo_Paradrop_DropZones", _registry];
private _public = missionNamespace getVariable ["Waldo_Paradrop_PublicDropZones", []];
_public = _public select {(_x select 0) != _id};
missionNamespace setVariable ["Waldo_Paradrop_PublicDropZones", _public, true];
diag_log format ["[WMP PARADROP] Removed id=%1 deleteAircraft=%2", _id, _deleteAircraft];
if (!isNull _requester && {_notifyRequester}) then {
    ["DYNAMIC PARADROP", "Operation state and associated map markers removed.", "SUCCESS", "PARADROP_REMOVE", 6] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _requester];
};
true

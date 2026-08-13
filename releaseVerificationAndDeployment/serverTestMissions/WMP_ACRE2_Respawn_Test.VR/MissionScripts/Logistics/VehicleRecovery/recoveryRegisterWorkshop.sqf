/*
 * Author: WaldoTheWarfighter
 * Registers or updates a server-owned vehicle-recovery workshop. The workshop key links registered
 * damaged vehicles to this destination. The server publishes object state, maintains the workshop
 * registry/monitor, and optionally creates a global area marker plus exact-position marker. Eden
 * object init fields run everywhere, so non-server copies are ignored. ZEN sends live requests
 * through the validated server runtime bridge.
 *
 * Locality and authority:
 * The server owns workshop registry, markers and recovery placement. Eden client copies exit;
 * published workshop state supplies current players, JIP clients and diagnostics.
 *
 * Arguments:
 * 0: workshop <OBJECT> - existing object representing the repair/recovery destination.
 * 1: key <STRING> - stable link used by recoverable vehicles (default: "MAIN").
 * 2: radius <NUMBER> - vehicle return/search radius in metres, minimum 5 (default: 50).
 * 3: serviced side <SIDE or STRING> - use "ALL" for every side, or west/east/independent/civilian
 *    for one side (default "ALL"). `sideUnknown` remains accepted internally for ZEN compatibility.
 * 4: notification radius <NUMBER> - audience radius in metres; -1 uses mission config (default: -1).
 * 5: create markers <BOOL> - create area and exact-position map markers (config default).
 *
 * Return Value:
 * Boolean - true when registered (or when a duplicate non-server Eden copy was ignored); otherwise false.
 *
 * Example:
 * [repairDepot, "FOB_ALPHA", 50, "ALL", 100, true]
 *     call Waldo_fnc_RecoveryRegisterWorkshop;
 * Result: repairDepot becomes the FOB_ALPHA workshop with a 50 m service area and local notices.
 *
 * Current callers: Vehicle Recovery ZEN workshop module, audit mission and mission-maker setup.
 */
params [
    ["_workshop", objNull, [objNull]],
    ["_key", "MAIN", [""]],
    ["_radius", 50, [0]],
    ["_side", "ALL", [sideUnknown, ""]],
    ["_notificationRadius", -1, [0]],
    ["_createMarker", missionNamespace getVariable ["Waldo_Recovery_CreateWorkshopMarkers", true], [true]]
];
if (isNull _workshop) exitWith {false};
if (!isServer) exitWith {true};
private _authorized = true;
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    _authorized = !isNull _caller && {!isNull getAssignedCuratorLogic _caller};
};
if (!_authorized) exitWith {false};
if (_side isEqualType "") then {
    _side = switch (toUpperANSI _side) do {
        case "WEST": {west};
        case "BLUFOR": {west};
        case "EAST": {east};
        case "OPFOR": {east};
        case "INDEPENDENT": {independent};
        case "GUER": {independent};
        case "CIVILIAN": {civilian};
        default {sideUnknown};
    };
};
_key = [_key, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
if (_key == "") exitWith {false};
_workshop setVariable ["Waldo_Recovery_Workshop", true, true];
_workshop setVariable ["Waldo_Recovery_WorkshopKey", toUpperANSI _key, true];
_workshop setVariable ["Waldo_Recovery_Radius", _radius max 5, true];
_workshop setVariable ["Waldo_Recovery_Side", _side, true];
_workshop setVariable [
    "Waldo_Recovery_NotificationRadius",
    if (_notificationRadius < 0) then {missionNamespace getVariable ["Waldo_Recovery_NotificationRadius", 100]} else {_notificationRadius},
    true
];
_workshop setVariable ["Waldo_Recovery_CreateMarker", _createMarker, true];
private _oldMarkers = _workshop getVariable ["Waldo_Recovery_Markers", []];
{deleteMarker _x} forEach _oldMarkers;
private _markerNames = [];
if (_createMarker) then {
    private _markerSuffix = ((netId _workshop) splitString ":") joinString "_";
    private _areaName = format ["Waldo_Recovery_WorkshopArea_%1", _markerSuffix];
    private _positionName = format ["Waldo_Recovery_WorkshopPosition_%1", _markerSuffix];
    private _markerColour = switch (_side) do {
        case east: {"ColorOPFOR"};
        case independent: {"ColorIndependent"};
        case civilian: {"ColorCivilian"};
        default {"ColorBLUFOR"};
    };
    createMarker [_areaName, getPosWorld _workshop];
    _areaName setMarkerShape "ELLIPSE";
    _areaName setMarkerBrush "SolidBorder";
    _areaName setMarkerColor _markerColour;
    _areaName setMarkerAlpha 0.18;
    _areaName setMarkerSize [_radius max 5, _radius max 5];
    createMarker [_positionName, getPosWorld _workshop];
    _positionName setMarkerType "mil_dot";
    _positionName setMarkerColor _markerColour;
    _positionName setMarkerText format ["Vehicle Recovery Workshop (%1)", toUpperANSI _key];
    _markerNames = [_areaName, _positionName];
};
_workshop setVariable ["Waldo_Recovery_Markers", _markerNames];
private _workshops = (missionNamespace getVariable ["Waldo_Recovery_Workshops", []]) select {!isNull _x};
_workshops pushBackUnique _workshop;
missionNamespace setVariable ["Waldo_Recovery_Workshops", _workshops];
if !(missionNamespace getVariable ["Waldo_Recovery_MonitorRunning", false]) then {[] spawn Waldo_fnc_RecoveryMonitorServer};
true

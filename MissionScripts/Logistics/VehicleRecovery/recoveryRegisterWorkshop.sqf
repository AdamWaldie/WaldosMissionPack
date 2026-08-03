/* Registers a server-owned recovery workshop. [object, key, radius, serviced side, notification radius, create marker] */
params [
    ["_workshop", objNull, [objNull]],
    ["_key", "MAIN", [""]],
    ["_radius", 50, [0]],
    ["_side", sideUnknown, [sideUnknown]],
    ["_notificationRadius", -1, [0]],
    ["_createMarker", missionNamespace getVariable ["Waldo_Recovery_CreateWorkshopMarkers", true], [true]]
];
if (isNull _workshop) exitWith {false};
if (!isServer) exitWith {[_workshop, _key, _radius, _side, _notificationRadius, _createMarker] remoteExecCall ["Waldo_fnc_RecoveryRegisterWorkshop", 2]; true};
private _authorized = true;
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    _authorized = !isNull _caller && {!isNull getAssignedCuratorLogic _caller};
};
if (!_authorized) exitWith {false};
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
